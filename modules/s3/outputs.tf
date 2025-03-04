output "bucket_name" {
  description = "S3バケットの名前"
  value       = aws_s3_bucket.normal_bucket.bucket
}

output "source_arn" {
  value = aws_s3_bucket.normal_bucket.arn
}

output "bucket_id" {
  value = aws_s3_bucket.normal_bucket.id
}
