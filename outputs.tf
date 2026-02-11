#################################################################
# VPC
#################################################################

output "vpc-id" {
  value = module.vpc.vpc_id
}

output "eks-cluster-endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks-cluster-arn" {
  value = module.eks.cluster_arn
}

output "eks-cluster-name" {
  value = module.eks.cluster_name
}

output "availability-zones" {
  value = [for az in module.vpc.azs : az]
}

output "public-subnet-ids" {
  description = "Public subnet for all external-facing instances"
  value = module.vpc.public_subnets
}

output "private-subnet-ids" {
  description = "Subnet AZ1 for creating Confluent Cluster"
  value = module.vpc.private_subnets
}
