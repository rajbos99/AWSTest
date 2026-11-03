variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_a_id" {
  type    = string
  default = "000000000000"
}

variable "account_b_id" {
  type    = string
  default = "111111111111"
}

variable "target_s3_bucket_name" {
  type    = string
  default = "account-b-production-data-111111111111"
}

variable "ci_build_artifacts_bucket" {
  type    = string
  default = "production-ci-build-artifacts-000000000000"
}

variable "ci_ecr_repo_name" {
  type    = string
  default = "production-app-repo"
}

variable "ci_ecs_cluster_name" {
  type    = string
  default = "production-cluster"
}

variable "ci_ecs_service_name" {
  type    = string
  default = "production-service"
}
