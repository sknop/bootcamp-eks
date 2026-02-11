#################################################################
# Provider
#################################################################
provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

#################################################################
# Availability Zones
#################################################################

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

#################################################################
# Locals
#################################################################

locals {
  name               = "ex-${basename(path.cwd)}"
  kubernetes_version = "1.34"

  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    name       = local.name
    cflt_environment = var.cflt_environment
    cflt_partition = var.cflt_partition
    cflt_managed_by	= var.cflt_managed_by
    cflt_managed_id	= var.cflt_managed_id
    cflt_service      = var.cflt_service
    cflt_environment  = var.cflt_environment
    cflt_keep_until   = local.keep_until_date
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                   = local.name
  kubernetes_version     = local.kubernetes_version
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name
  cidr = var.vpc-cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc-cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc-cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc-cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}