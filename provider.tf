provider "aws" {
  region = "eu-west-2"
   assume_role {
    role_arn = "arn:aws:iam::627754054627:role/AtlantisDeployRole"
  }
}