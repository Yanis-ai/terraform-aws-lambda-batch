resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "normal_bucket" {
  bucket        = "${var.bucket_name_prefix}-${random_string.suffix.result}"
  force_destroy = true
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_versioning" "normal_bucket_versioning" {
  bucket = aws_s3_bucket.normal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "normal_bucket_encryption" {
  bucket = aws_s3_bucket.normal_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_ownership_controls" "normal_bucket_ownership_controls" {
  bucket = aws_s3_bucket.normal_bucket.bucket
  rule {
    object_ownership = "ObjectWriter"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_acl" "normal_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.normal_bucket_ownership_controls]
  bucket     = aws_s3_bucket.normal_bucket.id
  acl        = "private"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_public_access_block" "normal_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.normal_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  lifecycle {
    ignore_changes = all
  }
}
