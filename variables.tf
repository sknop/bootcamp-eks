variable "region"  {
    type = string
    default = "eu-west-1"
}

variable "vpc-cidr" {
  default = "172.32.0.0/16"
  description = "The CIDR block for your VPC"
  type = string
}

variable "keep-until" {
  type = number
  default = 2
}

#################################################################
# Confluent Tags
#################################################################

variable "username" {
  type = string
  default = "user"
}

#################################################################
# Confluent Tags
#################################################################

variable "cflt_environment" {
  default = "dev"
}

variable "cflt_partition" {
  default = "training"
}

variable "cflt_managed_by" {
  type = string
  default = "sven"
}

variable "cflt_managed_id" {
  default = "user"
}

variable "cflt_service" {
  description = "This is the theatre of operation, like EMEA or APAC"
  type = string
  default = "EMEA"
}
