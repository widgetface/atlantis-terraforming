terraform {
  backend "s3" {
    bucket         = "sdds-terraform-state-bucket"
    key            = "envs/dev/terraform.tfstate"  # Adjust path if needed
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"             # Optional but recommended
    encrypt        = true
  }
}