resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket = "my-secure-bucket-${random_id.suffix.hex}"
  force_destroy = false  # set to true only if you want to allow auto-deletion of objects
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true  # Adds protection against accidental deletion
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}