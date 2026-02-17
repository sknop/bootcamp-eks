# BOOTCAMP-EKS

A set of Terraform scripts to create a complete EKS environment in AWS.

## Deploy EKS in AWS together with a VPC

Usage:

    cp terraform.tfvars.template terraform.tfvars
    vi terraform.tfvars # adjust to your liking, pick your desired region, and ensure username is unique within the org

    terraform init
    terraform plan # optional
    terraform apply # -auto-approve if you feel confident

You then need to set the local context for Kubernetes. The command required is in the output of the Terraform script.
The alias name is optional but nice to have. We do this manually rather than automatically to avoid any potential issues.

List existing contexts:

    kubectl config get-contexts

Delete any old context that do not apply anymore (`terraform destroy` will **not** clean these up):

    kubectl config delete-context <CLUSTER NAME>
    
Use the `configure_kubectl` output of the Terraform script to find the command to set up the correct context.

## Kubernetes setup

The next step is to set up the storage class for gp3 by running

    kubectl apply -f storage.yaml
    kubectl get storageclass

The latter command should show a gp2 and the new default gp3 storage class.

Now we need to set the node class and node pool for auto-scaling:

    kubectl apply -f nodeclass.yaml --server-side --force-conflicts
    kubectl apply -f nodepool.yaml --server-side --force-conflicts

Why --server-side? It suppresses the warning that we overwrite an existing configuration.
Why --force-conflicts? We are taking over the control from other managers, so we need to confirm we want to do that.

Finally, there is a nice management gui for Kubernetes now called Headlamp, that can be installed thus:

    helm repo add headlamp https://kubernetes-sigs.github.io/headlamp
    helm upgrade --install headlamp headlamp/headlamp --namespace headlamp --create-namespace
    
To start up headlamp, create a token, export some variables and set up port forwarding

    kubectl create token headlamp --namespace headlamp --duration=24h # JWT token

    export POD_NAME=$(kubectl get pods --namespace headlamp -l "app.kubernetes.io/name=headlamp,app.kubernetes.io/instance=headlamp" -o jsonpath="{.items[0].metadata.name}"
    export CONTAINER_PORT=$(kubectl get pod --namespace headlamp $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
    
    kubectl --namespace headlamp port-forward $POD_NAME 8080:$CONTAINER_PORT

## Deploy CFK and a CP cluster

Set up the Helm Chart:

    helm repo add confluentinc https://packages.confluent.io/helm

Install Confluent For Kubernetes using Helm:

    helm upgrade --install operator confluentinc/confluent-for-kubernetes --namespace confluent

Check that the Confluent For Kubernetes pod comes up and is running:s

    kubectl get pods --namespace confluent

## Deploy the security manager

    helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.19.2 \
    --set crds.enabled=true \
    --create-namespace

Maybe try its own namespace?

## Deploy CP-Flink

    helm upgrade --install cp-flink-kubernetes-operator confluentinc/flink-kubernetes-operator
    helm upgrade --install cmf confluentinc/confluent-manager-for-apache-flink
