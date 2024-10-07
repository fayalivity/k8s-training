kc get --namespace kube-system all
kc get --namespace kube-system daemonset
kc create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0
kc scale deployment hello-world --replicas=5
kc get deployments
kc delete deployment hello-world
# 3.2-deployment.yaml
kc apply -f deployment.yaml
