# Limitation des ressources dans un namespace

Dans cet exercice, nous allons créer un namespace et définir des limites d'utilisation de ressources pour chaque Pod qui sera déployé dans celui-ci.

## Création d'un namespace

Créez le namespace *test* en utilisant la commande suivante:

```
$ kubectl create namespace test
```

## Définition de limites d'utilisation des ressources

La spécification suivante définit une ressource de type *LimitRange* qui fixe une limite d'utilisation de la mémoire pour chaque container qui sera créé dans le namespace *test*. Copiez cette spécification dans le fichier *limit.yaml*:

```
apiVersion: v1
kind: LimitRange
metadata:
  name: memory-limit-range
spec:
  limits:
  - default:
      memory: 128M
    defaultRequest:
      memory: 64M
    max:
      memory: 256M
    type: Container
```

Créez la ressource correspondante dans le namespace *test*:

```
$ kubectl apply -f limit.yaml --namespace=test
```

## Lancement d'un Pod sans spécification de ressource

La spécification suivante définit un Pod avec un unique container, celui-ci ne définit pas de requests ni de limits pour l'utilisation des ressources. Copiez cette spécification dans le fichier www-1.yaml:

```
apiVersion: v1
kind: Pod
metadata:
  name: www-1
spec:
  containers:
  - name: www
    image: nginx:1.18-alpine
```

Créez ce Pod dans le namespace *test*:

```
$ kubectl apply -f www-1.yaml -n test
```

Regardez ensuite la configuration du Pod:

```
$ kubectl describe po www-1 -n test
```

Vous devriez observer que les propriétés *Requests* et *Limits* ont été ajoutées dans le container du Pod, celles-ci ont les valeurs spécifiées dans la ressource LimitRange.

```
...
Containers:
  www:
    Container ID:   containerd://11b259e95b68ade3e014fc994e11ea22b0a5c31d0896c845811dad4ad073ba87
    Image:          nginx:1.18-alpine
    Image ID:       docker.io/library/nginx@sha256:93baf2ec1bfefd04d29eb070900dd5d79b0f79863653453397e55a5b663a6cb1
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 21 Sep 2021 19:00:11 +0200
    Ready:          True
    Restart Count:  0
    Limits:
      memory:  128M         <-- Valeur de .spec.limits.default.memory de la ressource LimitRange
    Requests:
      memory:     64M       <-- Valeur de .spec.limits.defaultRequest.memory de la ressource LimitRange
...
```

## Lancement d'un Pod avec une spécification de ressource correcte

La spécification suivante définit un Pod avec un unique container, celui-ci définit des valeurs pour les requests et limits de mémoire. Copiez cette spécification dans le fichier www-2.yaml:

```
apiVersion: v1
kind: Pod
metadata:
  name: www-2
spec:
  containers:
  - name: www
    image: nginx:1.18-alpine
    resources:
      limits:
        memory: 120M
      requests:
        memory: 100M
```

Créez ce Pod dans le namespace *test*

```
$ kubectl apply -f www-2.yaml -n test
```

Regardez ensuite la configuration du Pod:

```
$ kubectl describe po www-2 -n test
```

Vous devriez observer que les propriétés *Requests* et *Limits* n'ont pas été modifiées, elles sont dans l'intervalle accepté par la ressource LimitRange.

```
...
Containers:
  www:
    Container ID:   containerd://7bef304d43a3a72ffb39623b11e0f4d45f6ceeb4ee5409e047f414f22f099515
    Image:          nginx:1.18-alpine
    Image ID:       docker.io/library/nginx@sha256:93baf2ec1bfefd04d29eb070900dd5d79b0f79863653453397e55a5b663a6cb1
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 21 Sep 2021 19:52:06 +0200
    Ready:          True
    Restart Count:  0
    Limits:
      memory:  120M      <-- valeur inchangée
    Requests:
      memory:     100M   <-- valeur inchangée
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hmlh5 (ro)
...
```

## Lancement d'un Pod avec une spécification de ressource incorrecte

La spécification suivante définit un Pod avec un unique container, celui-ci définit des valeurs pour les requests et limits de mémoire (cette dernière étant cependant en dehors de l'intervalle accepté par le LimitRange). Copiez cette spécification dans le fichier www-3.yaml:

```
apiVersion: v1
kind: Pod
metadata:
  name: www-3
spec:
  containers:
  - name: www
    image: nginx:1.18-alpine
    resources:
      limits:
        memory: 512M
      requests:
        memory: 64M
```

Créez ensuite ce Pod dans le namespace *test*

```
$ kubectl apply -f www-3.yaml -n test
```

Vous devriez obtenir un message semblable à celui ci-dessous:

```
Error from server (Forbidden): error when creating "www-3.yaml": pods "www-3" is forbidden: maximum memory usage per Container is 256M, but limit is 512M
```

Ce nouveau Pod ne peut pas être créé car sa spécification contient une limite de mémoire (.spec.containers[0].resources.limits.memory) supérieure à la valeur maximale acceptée par le LimitRange.

## Cleanup

Supprimez le namespace avec la commande suivante:

```
$ kubectl delete ns test
```
