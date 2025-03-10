terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL for sending notifications"
  type        = string
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name      = "demo"
  base_name = "${local.name}-${random_string.suffix.result}"
}

module "vpc" {
  source = "tfstack/vpc/aws"

  region             = "ap-southeast-1"
  vpc_name           = local.name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = data.aws_availability_zones.available.names

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  eic_subnet = "jumphost"

  jumphost_instance_create     = true
  jumphost_log_prevent_destroy = false
  jumphost_subnet              = "10.0.0.0/24"
  jumphost_allow_egress        = true

  create_igw = true
  ngw_type   = "single"
}

data "aws_ebs_volume" "jumphost" {
  most_recent = true
  filter {
    name   = "attachment.instance-id"
    values = [module.vpc.jumphost_instance_id]
  }
}

# Outputs
output "all_module_outputs" {
  description = "All outputs from the AWS metric alarm Slack notifier module"
  value       = module.billing_alert
}
