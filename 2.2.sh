kubectl config get-contexts

kubectl config use-context kubernetes-admin@k8s-master-1
kubectl cluster-info

kubectl api-resources | more

kubectl explain pods | more

kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more

# Create pod.yaml file
# Deploy pod
kubectl apply -f pod.yaml

kubectl get pods
kubectl delete pod hello-world

# Use previous deployment.yaml file
kubectl apply -f deployment.yaml --dry-run=server
kubectl get deployments # normal if nothing to display
kubectl apply -f deployment.yaml --dry-run=client

kubectl apply -f deployment-error.yaml --dry-run=client # Error in the script (normal behavior)

kubectl create deployment nginx --image=nginx --dry-run=client
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml | more

kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment-generated.yaml
kubectl apply -f deployment-generated.yaml
kubectl delete -f deployment-generated.yaml

kubectl apply -f deployment.yaml

kubectl diff -f deployment-new.yaml | more

kubectl delete -f deployment.yaml

kubectl api-resources --api-group=apps

kubectl explain deployment --api-version apps/v1 | more

kubectl api-versions | sort | more

## Demo : API Requests (-v verbose)
kubectl apply -f pod.yaml
kubectl get pod hello-world
kubectl get pod hello-world -v 6
# result: GET https://192.168.1.56:6443/api/v1/namespaces/default/pods/hello-world 200 OK
kubectl get pod hello-world -v 7
kubectl get pod hello-world -v 8
kubectl get pod hello-world -v 9

kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world | head -n 20

fg
ctrl+c

kubectl get pods --watch -v 6 &

netstat -plan | grep kubectl
kubectl delete pods hello-world

# kill foreground process
fg
ctrl+c

kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world/log

# authentication failure demo
cp ~/.kube/config ~/.kube/config.ORIG # backup
vi ~/.kube/config
# then replace users.name adding 1 to the usename

kubectl get pods -v 6 # use fake user/password

cp ~/.kube/config.ORIG ~/.kube/config

kubectl get pods nginx-pod -v 6
kubectl apply -f deployment.yaml  -v 6
kubectl get deployments

kubectl delete deployments hello-world -v 6
kubectl delete pod hello-world