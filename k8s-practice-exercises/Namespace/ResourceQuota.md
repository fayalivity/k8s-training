# Limitation des ressources dans un namespace

Dans cet exercice, nous allons créer un namespace et ajouter des quotas afin de limiter les ressources pouvant être utilisées dans celui-ci.

## Création d'un namespace

Créez le namespace *test*:

```
kubectl create namespace test
```

## Quota d'utilisation des ressources

Copiez, dans le fichier *quota.yaml*, le contenu ci-dessous.

```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
```

Celui-ci défini une ressource de type *ResourceQuota* qui limitera l'utilisation de la mémoire et du cpu dans le namespace associé. Au sein de celui-ci:

- chaque container devra spécifier des demandes et des limites pour la RAM et le cpu
- l'ensemble des containers ne pourra pas demander plus de 1GB de RAM
- l'ensemble des containers ne pourra pas utiliser plus de 2GB de RAM
- l'ensemble des containers ne pourra pas demander plus d'1 cpu
- l'ensemble des containers ne pourra pas utiliser plus de 2 cpus

En utilisant la commande suivante, créez cette nouvelle ressource en l'associant au namespace *test*.

```
kubectl apply -f quota.yaml --namespace=test
```

## Lancement d'un Pod

Créez un fichier pod-quota-1.yaml, et copiez le contenu suivant:

```
apiVersion: v1
kind: Pod
metadata:
  name: quota-mem-cpu-1
  namespace: test
spec:
  containers:
  - name: www
    image: nginx:1.22
    resources:
      limits:
        memory: "800Mi"
        cpu: "800m"
      requests:
        memory: "600Mi"
        cpu: "400m"
```

L'unique container de ce Pod définit des demandes et des limites pour la RAM et le CPU.

Créez ce Pod avec la commande suivante:

```
kubectl apply -f pod-quota-1.yaml
```

Vérifiez que le Pod a été créé correctement:

```
$ kubectl get po -n test
NAME                 READY   STATUS    RESTARTS   AGE
quota-mem-cpu-1      1/1     Running   0          11s
```

## Vérification de l'utilisation du quota

Utilisez la commande suivante pour voir les ressources RAM et CPU utilisées au sein du namespace:

```
kubectl describe resourcequota quota --namespace=test
```

## Lancement d'un 2ème Pod

Créez un fichier pod-quota-2.yaml, et copiez le contenu suivant:

```
apiVersion: v1
kind: Pod
metadata:
  name: quota-mem-cpu-2
  namespace: test
spec:
  containers:
  - name: db
    image: mongo:5.0
    resources:
      limits:
        memory: "1Gi"
        cpu: "800m"      
      requests:
        memory: "700Mi"
        cpu: "400m"
```

Créez ce Pod avec la commande suivante:

```
kubectl apply -f pod-quota-2.yaml
```

Vous devriez obtenir un message semblable à celui ci-dessous

```
Error from server (Forbidden): error when creating "pod-quota-2.yaml": pods "quota-mem-cpu-2" is forbidden: exceeded quota: quota, requested: requests.memory=700Mi, used: requests.memory=600Mi, limited: requests.memory=1Gi
```

Ce nouveau Pod ne peut pas être créé car il n'y a pas assez de ressources disponibles dans le namespace *test*

## Pour aller plus loin

Modifiez le *RessourceQuota* afin de limiter le nombre de Pods à 5 dans le namespace

<details>
  <summary markdown="span">Indice</summary>

La limitation du nombre de Pods se fait en ajoutant la propriété *spec.hard.pods* comme indiqué ci-dessous:

```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "5"
```

</details>

Créez le Deployment suivant, celui-ci définit 5 réplicas d'un Pod basé sur nginx:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: test
  name: nginx
spec:
  replicas: 5
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.22
        name: nginx
        resources:
          limits:
            memory: "50Mi"
            cpu: "50m"      
          requests:
            memory: "50Mi"
            cpu: "50m"
```

Vérifiez que le 5ème Pod ne peut pas être lancé (le Deployment doit indiquer que seuls 4 pods sur les 5 demandés sont disponibles)

```
$ kubectl -n test get deploy nginx
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   4/5     4            4           26s
```

Les évènements vous indiquent qu'un pod supplémentaire ne peut pas être lancé en raison de la limitation (en terme de nombre de pods) spécifiée dans le quota:

```
kubectl get events -n test
```

## Cleanup

Supprimez le namespace *test*:

```
kubectl delete ns test
```
