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

Then we need to set up the context. We do this manually rather than automatically to avoid any potential issues.
List existing contexts:

    kubectl config get-contexts
    kubectl config delete-context <CLUSTER NAME>
    
Use the `configure_kubectl` output of the Terraform script to find the command to set up the correct context.

The next step is to set up the storage class for gp3 by running

    kubectl apply -f storage.yaml
    kubectl get storageclass

The latter command should show a gp2 and the new default gp3 storage class.


