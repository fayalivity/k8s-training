[kube-score](https://kube-score.com/) est un outils qui fait une analyse statique des spécifications yaml utilisées pour définir des ressources dans Kubernetes.

## Installation

Installez kube-score en installant la dernière release disponible pour votre environnment.
Les différentes releases sont disponible à l'adresse https://github.com/zegl/kube-score/releases

## Les actions disponibles

Lancez kube-score sans argument de façon à obtenir les différentes actions qui sont possibles:

```
$ kube-score
Usage of kube-score:
kube-score [action] --flags

Actions:
	score	Checks all files in the input, and gives them a score and recommendations
	list	Prints a CSV list of all available score checks
	version	Print the version of kube-score
	help	Print this message

Run "kube-score [action] --help" for more information about a particular command
```

Différentes options peuvent être utilisées, par exemple:

- l'utilisation de *--ignore-container-cpu-limit* permet de ne pas vérifier si les containers ont une limite de CPU
- l'utilisation de *--ignore-container-memory-limit permet de ne pas vérifier si les containers ont une limite de RAM

Utilisez la commande suivante afin de voir l'ensemble des vérifications qui sont faites par kube-score:

```
kube-score list
```

## Utilisation

1. Créez la spécification d'un Deployment, basé sur l'image *stefanprodan/podinfo* avec une commande impérative.

2. Lancez kube-score sur cette spécification

3. En vous aidant des informations que vous trouverez sur [https://github.com/stefanprodan/podinfo](https://github.com/stefanprodan/podinfo), modifiez la spécification de façon à supprimer certains problèmes *CRITIQUES* remontés par kube-score

Note: il ne sera peut-être pas possible de supprimer la totalité des problèmes

<details>
<summary markdown="span">Correction</summary>

1. Création de la spécification d'un Deployment basé sur podinfo:

```
kubectl create deployment podinfo --image=stefanprodan/podinfo --dry-run=client -o yaml > deploy.yaml
```

La spécification générée est la suivante:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: podinfo
  name: podinfo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: podinfo
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: podinfo
    spec:
      containers:
      - image: stefanprodan/podinfo
        name: podinfo
        resources: {}
status: {}
```

2. Lancement de kube-score sur la spécification:

```
kube-score score ./deploy.yaml
```

Vous obtiendrez le résultat suivant:

```
apps/v1/Deployment podinfo                                                    💥
    [CRITICAL] Container Resources
        · podinfo -> CPU limit is not set
            Resource limits are recommended to avoid resource DDOS. Set resources.limits.cpu
        · podinfo -> Memory limit is not set
            Resource limits are recommended to avoid resource DDOS. Set resources.limits.memory
        · podinfo -> CPU request is not set
            Resource requests are recommended to make sure that the application can start and run without crashing. Set resources.requests.cpu
        · podinfo -> Memory request is not set
            Resource requests are recommended to make sure that the application can start and run without crashing. Set resources.requests.memory
    [CRITICAL] Container Image Tag
        · podinfo -> Image with latest tag
            Using a fixed tag is recommended to avoid accidental upgrades
    [CRITICAL] Container Ephemeral Storage Request and Limit
        · podinfo -> Ephemeral Storage limit is not set
            Resource limits are recommended to avoid resource DDOS. Set resources.limits.ephemeral-storage
    [CRITICAL] Pod NetworkPolicy
        · The pod does not have a matching NetworkPolicy
            Create a NetworkPolicy that targets this pod to control who/what can communicate with this pod. Note, this feature needs to be supported
            by the CNI implementation used in the Kubernetes cluster to have an effect.
    [CRITICAL] Container Security Context User Group ID
        · podinfo -> Container has no configured security context
            Set securityContext to run the container in a more secure context.
    [CRITICAL] Container Security Context ReadOnlyRootFilesystem
        · podinfo -> Container has no configured security context
            Set securityContext to run the container in a more secure context.
```

3. La spécification peut être améliorer sur différents points

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: podinfo
  name: podinfo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: podinfo
  strategy: {}
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
      - image: stefanprodan/podinfo:6.1.0
        name: podinfo
        imagePullPolicy: Always
        securityContext:
          readOnlyRootFilesystem: true
          runAsUser: 11000
          runAsGroup: 11000
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
            ephemeral-storage: 30Mi
          limits:
            cpu: 50m
            memory: 64Mi
            ephemeral-storage: 30Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 9898
          initialDelaySeconds: 3
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /readyz
            port: 9898
          initialDelaySeconds: 3
          periodSeconds: 3
```

Relancez kube-score et vérifiez que cette nouvelle version corrige plusieurs des problèmes listés précédemment.

```
$ kube-score score ./podinfo.yaml

apps/v1/Deployment podinfo                                                    💥
    [CRITICAL] Pod NetworkPolicy
        · The pod does not have a matching NetworkPolicy
            Create a NetworkPolicy that targets this pod to control who/what can communicate with this pod. Note, this feature needs to be supported
            by the CNI implementation used in the Kubernetes cluster to have an effect.
```

Comme l'indique ce nouveau scan, il faudrait également créer une NetworkPolicy pour contrôler les communications entrantes et sortantes vers ce Pod.

:warning: la spécification précédente a été modifiée de façon à supprimer les erreurs listées par kube-score, il faudrait bien sur s'assurer que cela ne perturbe pas le fonctionnement de l'application.
</details>

