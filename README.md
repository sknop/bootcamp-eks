# BOOTCAMP-EKS

A set of Terraform scripts to create a complete EKS environment in AWS.

Usage:

    cp terraform.tfvars.template terraform.tfvars
    vi terraform.tfvars

    terraform init
    terraform plan # optional
    terraform apply # -auto-approve if you feel confident

You then need to set the local context for Kubernetes. The command required is in the output of the Terraform script.
The alias name is optional but nice to have.

The next step is to set up the storage class for gp3 by running

    kubectl apply -f storage.yaml

