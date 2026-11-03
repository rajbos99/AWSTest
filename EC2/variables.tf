variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "default_ami_id" {
  description = "Default Amazon Linux 2023 AMI for us-east-1"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "instances" {
  description = "Configuration map for EC2 instances"
  type = map(object({
    instance_type    = string
    root_volume_type = string
    root_volume_size = number
    iops             = optional(number)
    throughput       = optional(number)
    key_name         = string
    ami_id           = optional(string)
    subnet_id        = optional(string)
    environment      = string
    owner            = string
    prevent_destroy  = optional(bool, false)
  }))

  default = {
    "prod-db" = {
      instance_type    = "r6i.xlarge"
      root_volume_type = "io2"
      root_volume_size = 100
      iops             = 3000
      key_name         = "prod-db-key"
      environment      = "Production"
      owner            = "db-team"
      prevent_destroy  = true
    }
    "prod-api" = {
      instance_type    = "c6i.large"
      root_volume_type = "gp3"
      root_volume_size = 50
      iops             = 3000
      throughput       = 125
      key_name         = "prod-api-key"
      environment      = "Production"
      owner            = "backend-team"
      prevent_destroy  = false
    }
    "stage-web" = {
      instance_type    = "t3.medium"
      root_volume_type = "gp2"
      root_volume_size = 30
      key_name         = "stage-web-key"
      environment      = "Staging"
      owner            = "frontend-team"
      prevent_destroy  = false
    }
    "dev-worker" = {
      instance_type    = "t3.small"
      root_volume_type = "standard"
      root_volume_size = 20
      key_name         = "dev-worker-key"
      environment      = "Development"
      owner            = "data-team"
      prevent_destroy  = false
    }
    "mgmt-analytics" = {
      instance_type    = "m6i.large"
      root_volume_type = "io1"
      root_volume_size = 60
      iops             = 1500
      key_name         = "mgmt-analytics-key"
      environment      = "Management"
      owner            = "analytics-team"
      prevent_destroy  = false
    }
  }
}