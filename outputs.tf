#################################################################
# VPC
#################################################################

output "vpc-id" {
  value = module.vpc.vpc_id
}

output "eks-cluster-endpoint" {
  value = module.eks.cluster_endpoint
}