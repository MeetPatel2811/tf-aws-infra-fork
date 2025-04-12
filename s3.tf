resource "random_uuid" "s3_bucket_uuid" {}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "csye-${formatdate("YYYYMMDD", timestamp())}-${random_uuid.s3_bucket_uuid.result}"
  force_destroy = true
  acl           = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_config" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    id     = "transition_to_standard_ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
