provider "aws" {
  region = "ap-northeast-1"
}

variable "test_prefix" {
  description = "バッチテスト環境のプレフィックス"
  type        = string
  default     = "batch-test"
}

variable "bucket_name_prefix" {
  description = "S3バケット名のプレフィックス"
  default     = "batch-test-bucket"
}

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name_prefix = var.bucket_name_prefix
}

output "bucket_name" {
  value = module.s3_bucket.bucket_name
}

# 执行生成测试文件的脚本
resource "null_resource" "execute_script" {
  depends_on = [module.s3_bucket]
  provisioner "local-exec" {
    command = "./00_generate_and_upload_script.sh"
  }
}

# 将生成的测试文件上传到 S3 的 input 目录，并清理本地文件
resource "null_resource" "upload_files" {
  depends_on = [null_resource.execute_script]
  provisioner "local-exec" {
    command = <<EOT
      aws s3 cp ./testfiles/ s3://${module.s3_bucket.bucket_name}/input/ --recursive
      rm -f ./testfiles/*
    EOT
  }
}

# 创建 Lambda 函数
resource "aws_lambda_function" "unzip_lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "unzipLambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  runtime          = "python3.9"

  environment {
    variables = {
      BUCKET_NAME  = module.s3_bucket.bucket_name
      OUTPUT_DIR   = "output/"
      INPUT_PREFIX = "input/"
    }
  }

  depends_on = [
    module.s3_bucket.normal_bucket,
    null_resource.execute_script
  ]
}

# 创建 Lambda 执行的 IAM 角色
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 取消 S3 事件通知，改为手动调用 Lambda

# 上传文件完成后，调用 Lambda 函数
resource "null_resource" "invoke_lambda" {
  depends_on = [null_resource.upload_files]
  provisioner "local-exec" {
    command = <<EOT
      aws lambda invoke --function-name ${aws_lambda_function.unzip_lambda.function_name} --payload '{}' response.json
    EOT
  }
}
