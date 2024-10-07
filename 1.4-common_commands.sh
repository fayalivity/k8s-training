kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide
kubectl get pods
kubectl get pods --namespace kube-system
kubectl get pods --namespace kube-system -o wide
kubectl get all --all-namespaces
kubectl get all --all-namespaces | more
kubectl api-resources | more
kubectl get ns
kubectl get po
kubectl get no
kubectl api-resources | grep pod
kubectl explain pod | more
kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more
kubectl explain pod --recursive | more
kubectl describe nodes
kubectl describe nodes k8s-master-1
kubectl describe nodes k8s-node-2
kubectl -h
kubectl get -h
kubectl create -h | more

# bash completion for kc
sudo apt install -y bash-completion
sudo apt update
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
kubectl get pod --all-namespaces

# deploy application
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0
kubectl run hello-world-pod --image=gcr.io/google-samples/hello-app:1.0

# go into container - list container with containerd executor
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps # from node
kubectl logs hello-world-pod # from master
kubectl exec -it hello-world-pod -- bash # from master

kubectl get deployment hello-world
kubectl get replicaset
kubectl get pods

kubectl describe deployment hello-world | more
kubectl describe replicaset hello-world | more

kubectl expose deployment hello-world \
    --port=80 \
    --target-port=8080

kubectl get service hello-world
kubectl describe service hello-world

curl http://10.103.183.96:80

kubectl get endpoints hello-world

kubectl get deployment hello-world -o yaml | more
kubectl get deployment hello-world -o json | more

kubectl get all
kubectl delete service hello-world
kubectl delete deployment hello-world
kubectl delete pod hello-world-pod
kubectl get all

kubectl create deployment hello-world \
    --image=gcr.io/google-samples/hello-app:1.0 \
    --dry-run=client -o yaml | more

kubectl create deployment hello-world \
    --image=gcr.io/google-samples/hello-app:1.0 \
    --dry-run=client -o yaml > deployment.yaml

kubectl apply -f deployment.yaml

kubectl expose deployment hello-world \
    --port=80 --target-port=8080 \
    --dry-run=client -o yaml > service.yaml

kubectl apply -f service.yaml
# modify replica
vi deployment.yaml
# change spec.replicas from 1 t0 20
# redeploy for update
kubectl apply -f deployment.yaml

kubectl get service hello-world
curl http://HOST:PORT

kubectl edit deployment hello-world
# change value of spec.replica to 30

kubectl get deployment hello-world

kubectl scale deployment hello-world --replicas=40
kubectl get deployment hello-world

kubectl delete deployment hello-world
kubectl delete service hello-world
kubectl get all