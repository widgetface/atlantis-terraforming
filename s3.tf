# Define the S3 bucket resource
resource "aws_s3_bucket" "test_bucket" {
  bucket = "sdds-test-bucket-eu-west-2"  # Ensure the bucket name is globally unique

  # Optional: Enable versioning on the S3 bucket
  versioning {
    enabled = true
  }

  # Optional: Enable server-side encryption
  server_side_encryption_configuration {
    rule {
      actions = ["AES256"]
    }
  }

  # Optional: Define tags for the S3 bucket
  tags = {
    Name        = "test-bucket"
    Environment = "Development"
  }
}