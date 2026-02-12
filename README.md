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

Now we need to set the node class and node pool for auto scaling:

    kubectl apply -f nodeclass.yaml --server-side
    kubectl apply -f nodepool.yaml --server-side --force-conflicts

Why --server-side? It suppresses the warning that we overwrite an existing configuration.
Why --force-conflicts? We are taking over the control from other managers, so we need to confirm we want to do that.

Finally, there is a nice management gui for Kubernetes now called Headlamp, that can be installed thus:

    helm repo add headlamp https://kubernetes-sigs.github.io/headlamp
    helm upgrade --install headlamp headlamp/headlamp --namespace headlamp --create-namespace
    
To start up headlamp, create a token, export some variables and set up port forwarding

    kubectl create token headlamp --namespace headlamp
    export POD_NAME=$(kubectl get pods --namespace headlamp -l "app.kubernetes.io/name=headlamp,app.kubernetes.io/instance=headlamp" -o jsonpath="{.items[0].metadata.name}"
    export CONTAINER_PORT=$(kubectl get pod --namespace headlamp $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
    
    kubectl --namespace headlamp port-forward $POD_NAME 8080:$CONTAINER_PORT

