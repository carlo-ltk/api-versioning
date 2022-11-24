terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "fnd-api-terraform-state"
    key            = "terraform.tfstate"
    dynamodb_table = "fnd-api-terraform-state-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
