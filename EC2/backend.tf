# use_lock_file  = true # Requires Terraform v1.9.0+ for native S3 state locking(We can avoid dynamodb table locking)
terraform {
  backend "s3" {
    bucket         = "prod-terraform-state-us-east-1-000000000000"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
