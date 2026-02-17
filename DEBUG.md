# Some debugging hints

Show me my current nodes

    kubectl get nodes -L node.kubernetes.io/instance-type -L karpenter.sh/capacity-type -L karpenter.sh/nodepool

Show my Persistent Volume claims

    kubectl get pvc

Headlamp is a great tool to visualize many of the aspects of Kubernetes

    export POD_NAME=$(kubectl get pods --namespace headlamp -l "app.kubernetes.io/name=headlamp,app.kubernetes.io/instance=headlamp" -o jsonpath="{.items[0].metadata.name}")
    export CONTAINER_PORT=$(kubectl get pod --namespace headlamp $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
    echo "Visit http://127.0.0.1:8080 to use your application"
    kubectl --namespace headlamp port-forward $POD_NAME 8080:$CONTAINER_PORT

Get the token using

    kubectl create token headlamp --namespace headlamp --duration=24h

Duration is optional but practical for longer debugging sessions.

