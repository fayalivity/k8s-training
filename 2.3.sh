# Creating namespace
# Add resource
# query
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=true | head
kubectl api-resources --namespaced=false | head
kubectl describe namespaces
kubectl describe namespaces kube-system
kubectl get pods --all-namespaces
kubectl get all --all-namespaces
kubectl get pods --namespace kube-system
kubectl create namespace playground1
kubectl create namespace Playground1
more namespace.yaml
vi namespace.yaml
more namespace.yaml
kubectl apply -f namespace.yaml
kubectl get namespaces
more deployment.yaml
vi deployment.yaml
# add namespace: namespace_name to the metadata block at name level
kubectl apply -f deployment.yaml
kubectl run hello-world-pod \
    --image=gcr.io/google-samples/hello-app:1.0 \
    --namespace playground1

kubectl get pods
kubectl get pods --namespace playground1
kubectl get pods -n playground1
kubectl get all --namespace=playground1
kubectl get pods -A
kubectl get pods -A -o wide
kubectl delete pods --all --namespace playground1
kubectl get pods -n playground1
kubectl delete namespaces playground1
kubectl delete namespaces playgroundinyaml

# use labels
create CreatePodsWithLabels.yaml
kubectl apply -f CreatePodsWithLabels.yaml
kubectl get pods --show-labels
kubectl describe pod nginx-pod-1  | head

kubectl get pods --selector tier=prod
kubectl get pods --selector tier=qa
kubectl get pods -l tier=prod
kubectl get pods -l tier=prod --show-labels

kubectl get pods -l 'tier=prod,app=MyWebApp' --show-labels
kubectl get pods -l 'tier=prod,app!=MyWebApp' --show-labels
kubectl get pods -l 'tier in (prod,qa)'
kubectl get pods -l 'tier notin (prod,qa)'

kubectl get pods -L tier
kubectl get pods -L tier,app

kubectl label pod nginx-pod-1  tier=non-prod --overwrite
kubectl get pod nginx-pod-1  --show-labels
kubectl label pod nginx-pod-1  another=Label
kubectl get pod nginx-pod-1  --show-labels
# removing label
kubectl label pod nginx-pod-1  another-
kubectl get pod nginx-pod-1  --show-labels
kubectl label pod --all tier=non-prod --overwrite
kubectl get pod --show-labels
kubectl delete pod -l tier=non-prod
kubectl get pods --show-labels

vi deployment-label.yaml
cat deployment
cat deployment-label.yaml
kubectl apply -f deployment-label.yaml
vi service.yaml
kubectl apply -f service.yaml
kubectl describe deployments.apps hello-world
kubectl describe replicasets hello-world
kubectl get pods --show-labels
kubectl label pod hello-world-5c7b5b8dfd-2wz8h pod-template-hash=DEBUG --overwrite
kubectl get pods --show-labels

kubectl get service
kubectl describe service hello-world
kubectl get pod -o wide
kubectl get pods --show-labels
kubectl label pod hello-world-5c7b5b8dfd-2wz8h app=DEBUG --overwrite
kubectl get pods --show-labels
kubectl describe endpoints hello-world
kubectl delete deployments.apps hello-world
kubectl delete service hello-world
kubectl delete pod hello-world-5c7b5b8dfd-2wz8h
kubectl get pods --show-labels