import boto3
import tarfile
import io
import os
import time
import csv

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = os.environ['BUCKET_NAME']
    output_dir = os.environ['OUTPUT_DIR']
    input_prefix = os.environ.get('INPUT_PREFIX', 'input/')

    csv_rows = []
    # CSV 表头：压缩文件名、解压该文件花费的时间（秒）
    csv_rows.append(["archive", "decompression_duration"])

    # 列出 input 目录下所有 tar.gz 文件
    response = s3.list_objects_v2(Bucket=bucket, Prefix=input_prefix)
    if 'Contents' in response:
        for obj in response['Contents']:
            key = obj['Key']
            if not key.endswith('.tar.gz'):
                continue
            print(f"Processing archive: {key}")
            archive_obj = s3.get_object(Bucket=bucket, Key=key)
            bytestream = io.BytesIO(archive_obj['Body'].read())
            
            start_time = time.time()
            with tarfile.open(fileobj=bytestream, mode='r:gz') as tar:
                for member in tar.getmembers():
                    file_content = tar.extractfile(member).read()
                    s3.put_object(Bucket=bucket, Key=f"{output_dir}{member.name}", Body=file_content)
            end_time = time.time()
            duration = end_time - start_time
            
            csv_rows.append([key, duration])
            print(f"Processed archive {key} in {duration} seconds")

    # 生成 CSV 内容
    csv_buffer = io.StringIO()
    csv_writer = csv.writer(csv_buffer)
    for row in csv_rows:
        csv_writer.writerow(row)
    
    # 将 CSV 文件上传到 output 目录
    csv_key = f"{output_dir}decompression_times.csv"
    s3.put_object(Bucket=bucket, Key=csv_key, Body=csv_buffer.getvalue())
    print(f"Uploaded CSV to {csv_key}")

    return {'status': 'Done'}
