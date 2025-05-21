
# Define the S3 bucket resource
resource "aws_s3_bucket" "test_bucket" {
    bucket = "sdds-test-bucket-cicd-west-2"   ##Ensure the bucket name is globally unique

# Optional: Enable versioning on the S3 bucket
  versioning {
    enabled = true
  }


#Optional: Define tags for the S3 bucket
  tags = {
    Name        = "test-bucket"
    Environment = "Development"
  }
}

 

# Define the S3 bucket resource
resource "aws_s3_bucket" "test_bucket2" {
    bucket = "sdds-test-bucket-2-cicd-west-2"   ##Ensure the bucket name is globally unique

# Optional: Enable versioning on the S3 bucket
  versioning {
    enabled = true
  }


#Optional: Define tags for the S3 bucket
  tags = {
    Name        = "test-bucket-2"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
   bucket = aws_s3_bucket.test_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "app2" {
   bucket = aws_s3_bucket.test_bucket2.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

 
 