## Exercise

1. Créez la spécification *podinfo.yaml* d'un Pod ayant un container basé sur l'image *stefanprodan/podinfo*. Nommez ce Pod *podinfo*.

2. Ajoutez une *livenessProbe* qui vérifie l'ouverture du port *9898* toutes les 10 seconds après un delai initial de 30 secondes.

3. Ajoutez une *readinessProbe* qui envoie une requête HTTP GET sur le endpoint */readyz* et le port *9898* toute les 5 secondes après un délai initial de 30 secondes.

4. Créez le Pod et assurez-vous que le container passe dans l'état *ready* au bout d'une trentaine de secondes.

5. Supprimez le Pod.

## Documentation

[https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

<details>
  <summary markdown="span">Solution</summary>

1. Créez la spécification *podinfo.yaml* d'un Pod ayant un container basé sur l'image *stefanprodan/podinfo*. Nommez ce Pod *podinfo*.

```
cat <<EOF > ./podinfo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: podinfo
spec:
  containers:
  - image: stefanprodan/podinfo
    name: podinfo
EOF
```

Note: vous pouvez également utiliser la commande impérative suivante pour créer cette spécification:

```
kubectl run podinfo --image=stefanprodan/podinfo --dry-run=client -o yaml > podinfo.yaml
```

2. Ajoutez une *livenessProbe* qui vérifie l'ouverture du port *9898* toutes les 10 seconds après un delai initial de 30 secondes

```
apiVersion: v1
kind: Pod
metadata:
  name: podinfo
spec:
  containers:
  - image: stefanprodan/podinfo
    name: podinfo
    livenessProbe:
      tcpSocket:
        port: 9898
      periodSeconds: 10
      initialDelaySeconds: 30
```

3. Ajoutez une *readinessProbe* qui envoie une requête HTTP GET sur le endpoint */readyz* et le port *9898* toute les 5 secondes après un délai initial de 30 secondes

```
apiVersion: v1
kind: Pod
metadata:
  name: podinfo
spec:
  containers:
  - image: stefanprodan/podinfo
    name: podinfo
    livenessProbe:
      tcpSocket:
        port: 9898
      periodSeconds: 10
      initialDelaySeconds: 30
    readinessProbe:
      httpGet:
        path: /readyz
        port: 9898
      periodSeconds: 5
      initialDelaySeconds: 30
```

4. Créez le Pod et assurez-vous que le container passe dans l'état *ready* au bout d'une trentaine de secondes.

Création du Pod:
```
kubectl apply -f podinfo.yaml
```

Vérification:
```
$ kubectl get po podinfo -w
NAME      READY   STATUS    RESTARTS   AGE
...
podinfo   0/1     Running   0          20s
podinfo   1/1     Running   0          32s
``` 

5. Supprimez le Pod

```
kubectl delete po podinfo
```

</details>

