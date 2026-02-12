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
  name               = "${var.username}-${basename(path.cwd)}"
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

  # Enable IRSA (OIDC) - equivalent to iam.withOIDC: true
  enable_irsa = true

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }
}


data "aws_eks_addon_version" "ebs_csi" {
  most_recent = true
  addon_name  = "aws-ebs-csi-driver"
  kubernetes_version =  local.kubernetes_version
}

data aws_caller_identity "current" { }

# Data source to generate the trust policy for the EKS Service Account
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      # Reference the OIDC Provider ARN output from the EKS module
      identifiers = [one(module.eks.oidc_provider_arn)]
    }

    condition {
      test     = "StringEquals"
      # Use the Cluster OIDC Issuer URL output and clean it up for the 'sub' condition
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      # Use the Cluster OIDC Issuer URL output and clean it up for the 'aud' condition
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM Role for the EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "EKS-${module.eks.cluster_name}-EBS-CSI-Driver-Role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json

  depends_on = [
    module.eks
  ]
}

# Attach the required AWS Managed Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_attach" {

  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

  depends_on = [
    aws_iam_role.ebs_csi_driver_role,
    module.eks
  ]
}

# Configure the EBS CSI Driver add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = one(module.eks.cluster_name)
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version  # "v1.53.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn

  # CRITICAL: Wait for the IAM Role components and OIDC provider to be ready
  depends_on = [
    aws_iam_role.ebs_csi_driver_role,
    aws_iam_role_policy_attachment.ebs_csi_driver_attach,
    # This ensures the OIDC provider resource is created before using its ARN/URL
    module.eks.oidc_provider_arn
  ]
}
