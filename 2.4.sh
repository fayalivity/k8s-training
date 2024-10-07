# runnin and managing pods
# StaticPods

kubectl get events --watch &
kubectl apply -f pod.yaml
kubectl apply -f deployment.yaml
cp deployment.yaml deploymentInNamespace.yaml
vi deployment
vi deployment.yaml
kubectl apply -f deployment.yaml
kubectl scale deployment hello-world --replicas=2
kubectl scale deployment hello-world --replicas=1
kubectl get deployments
kubectl get pods
kubectl -v 6 exec -it hello-world-5bc74c8b8d-2f5jv -- /bin/sh #no shell in container

# on execution node (k8d-node-2)
ps -aux | grep hello-app
kubectl port-forward hello-world-5bc74c8b8d-2f5jv 80:8080 # error is normal behavior
kubectl port-forward hello-world-5bc74c8b8d-2f5jv 8080:8080 &
curl http://localhost:8080 #during port forwarding
fg
ctrl+c
kubectl delete deployments hello-world
kubectl get pods
kubectl delete pod hello-world

kubectl run hello-world --image=gcr.io/google-samples/hello-app:2.0 --dry-run=client -o yaml --port=8080

# GO ON NODE (k8s-node-1)
sudo cat /var/lib/kubelet/config.yaml
sudo vi /etc/kubernetes/manifests/mypod.yaml
# past the content of dry-run output seen above

# RETURN ON MASTER
kubectl get pods -o wide
kubectl delete pod hello-world-k8s-node-1
kubectl get pods -o wide # pod still alive

# GO ON NODE 
sudo rm /etc/kubernetes/manifests/mypod.yaml

# RETURN ON MASTER
kubectl get pods -o wide # pod disappeared

vi multicontainer-pod.yaml
cat multicontainer-pod.yaml
kubectl apply -f multicontainer-pod.yaml
kubectl exec -it multicontainer-pod -- /bin/sh
kubectl exec -it multicontainer-pod --container consumer -- /bin/sh
kubectl port-forward multicontainer-pod 8080:80 &
curl http://localhost:8080


