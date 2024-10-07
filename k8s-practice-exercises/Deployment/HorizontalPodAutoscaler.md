# HorizontalPodAutoscaler

Dans cet exercice, nous allons utiliser une ressource de type *HorizontalPodAutoscaler* afin d'augmenter, ou de diminuer, automatiquement le nombre de réplicas d'un Deployment en fonction de l'utilisation du CPU.

## Création d'un Deployment

Copiez le contenu suivant dans le fichier *deploy.yaml*.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: w3
spec:
  selector:
    matchLabels:
      app: w3
  replicas: 1
  template:
    metadata:
      labels:
        app: w3
    spec:
      containers:
        - image: nginx:1.20-alpine
          name: w3
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 200m
```

Créez ensuite ce Deployment avec la commande suivante:

```
$ kubectl apply -f deploy.yaml
```

## Création d'un Service

Copiez le contenu suivant dans le fichier *svc.yaml*.

```
apiVersion: v1
kind: Service
metadata:
  name: w3
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: w3
```

Créez ensuite ce Service avec la commande suivante:

```
$ kubectl apply -f svc.yaml
```

## Installation du Metrics server

La ressource *HorizontalPodAutoscaler* utilise un composant externe nommé *metrics-server* pour récupérer les metrics de consommation des Pods (CPU / mémoire). Ces metrics seront ensuite utilisées pour augmenter ou diminuer automatiquement le nombre de Pods du Deployment en fonction de la charge.

Tout d'abord, vérifiez si le *metrics-server* est installé dans votre cluster:

```
kubectl get po -n kube-system -l k8s-app=metrics-server
```

Si cette commande retourne un Pod vous pouvez passer au paragraphe suivant. Si la commande ne retourne rien cela signifie que le *metrics-server* n'est pas installé, vous allez donc avoir besoin de le mettre en place, pour cela 2 cas de figure:

- Si vous utilisez Minikube

le lancement du *metrics-server* peut se faire simplement avec la commande suivante:

```
minikube addons enable metrics-server
```

- Si vous n'utilisez pas Minikube

il est nécessaire de déployer le process *metrics-server* avec la commande suivante:

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Accès aux métrics

Au bout de quelques dizaines de secondes, le *metrics-server* commencera à collecter des metrics. Vous pouvez le vérifier avec la commande suivante qui récupère la consommation CPU et mémoire des nodes:

```
$ kubectl top nodes
NAME            CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
workers-3ha6f   50m          2%     628Mi           20%
workers-3ha6x   92m          4%     644Mi           20%
workers-3ha6y   52m          2%     739Mi           23%
```

Note: cet exemple est obtenu sur un cluster constitué de 3 nodes

## Création de la ressource HorizontalPodAutoscaler

Nous allons maintenant définir un *HorizontalPodAutoscaler* qui sera en charge de modifier le nombre de réplicas du Deployment si celui-ci utilise plus de 10% du CPU qui lui est alloué (10% est une valeur très faible choisie simplement pour cet exemple, dans un contexte hors exercice, cette valeur sera plus élevée).

Créez un *hpa.yaml* avec le contenu suivant:

```
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-v2
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: w3
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 10
```

Créez ensuite cette ressource:

```
kubectl apply -f hpa.yaml
```

Vérifiez que l'HorizontalPodAutoscaler a été créé correctement:

```
kubectl get hpa
```

Vous obtiendrez un résultat proche du suivant:

```
NAME   REFERENCE       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa    Deployment/w3   0%/10%    1         10        0          9s
```

Note: il est possible que pendant quelques secondes la valeur de la colonne *TARGET* soit "<unknown>/10%", le temps que le hpa puisse récupérer les métrics de consommation des ressources.

## Test

Pour envoyer un grand nombre de requête sur le service *w3*, nous allons utiliser l'outils [Apache Bench](http://httpd.apache.org/docs/current/programs/ab.html).

Avec la commande suivante, lancez le Pod *ab* dont le rôle est d'envoyer des requêtes sur le service *w3* depuis l'intérieur du cluster:

```
kubectl run ab -ti --rm --restart='Never' --image=lucj/ab -- -n 200000 -c 100 http://w3/
```

Depuis un autre terminal observez l'évolution du nombre de réplicas (cela peux prendre quelques minutes):

```
$ kubectl get -w hpa
NAME     REFERENCE       TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
hpa      Deployment/w3   182%/10%   1         10        4          6m57s
hpa      Deployment/w3   97%/10%    1         10        8          7m2s
hpa      Deployment/w3   12%/10%    1         10        10         7m17s
hpa      Deployment/w3   0%/10%     1         10        10         7m32s
...
```

Note: l'option *-w* (watch)  met à jour régulièrement le résultat de la commande.

Vous allez observer ensuite la diminutaion du nombre de réplicas. Cette phase sera cependant un peu plus longue que celle observée lors de l'augmentation du nombre de réplicas (par défaut le *hpa* attend 5 minutes avant de faire diminuer le nombre de réplicas).

Note: il est possible de définir la façon dont le nombre de réplicas augmente ou diminue via l'utilisation des propriétés *.spec.behavior.scaleUp* et *.spec.behavior.scaleDown* dans la spécification de la resource *HPA*.

## Cleanup

Supprimez les différentes ressources créées dans cet exercice:

```
kubectl delete -f deploy.yaml -f svc.yaml -f hpa.yaml
```