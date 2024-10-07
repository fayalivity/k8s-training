## Exercice

Le but de cet exercice est de manipuler les namespaces et de comprendre comment les utiliser pour isoler les ressources

### 1. Création

Créez les 2 namespaces *development* et *production*

### 2. Liste des namespaces

Listez les namespaces présents

### 3. Création de Deployments

Créer le Deployment *www-0* basé sur nginx:1.24-alpine dans le namespace par défaut

Créer le Deployment *www-1* basé sur nginx:1.24-alpine dans le namespace *development*

Créer le Deployment *www-2* basé sur nginx:1.24-alpine dans le namespace *production*

### 4. Répartition des ressources

Listez les Deployments et Pods présents sur le système (l'option `--all-namespaces` ou `-A` permet de prendre en compte l'ensemble des namespaces)

### 5. Suppression

Supprimez les namespaces *development* et *production* ainsi que le deployment *www-0* créé dans le namespace *default*.

Listez une nouvelle fois les Deployments et Pods présents sur le système. Que constatez-vous ?

Note: comme nous le verrons par la suite, il est possible de définir des règles permettant de donner accès à des actions précises dans un namespace. Cette approche permet d'utiliser les namespaces pour isoler les ressources du cluster entre plusieurs équipes (dev, qa, prod) et/ou plusieurs clients.

---

## Correction

### 1. Création

Les commandes suivantes permettent de créer les namespaces *development* et *production*.

```
$ kubectl create namespace development
$ kubectl create namespace production
```

### 2. Liste des namespaces

La commande suivante permet de lister les namespaces présents sur le système.

```
kubectl get namespace
```

### 3. Création de Deployments

La commande suivante permet de créer le Deployment *www-0* dans le namespace par default

```
kubectl create deploy www-0 --image nginx:1.24-alpine
```

La commande suivante permet de créer le Deployment *www-1* dans le namespace *development*

```
kubectl create deploy www-1 --image nginx:1.24-alpine --namespace development
```

La commande suivante permet de créer le Deployment *www-2* dans le namespace *production*

```
kubectl create deploy www-2 --image nginx:1.24-alpine --namespace production
```

### 4. Répartition des ressources

La commande suivante permet de lister l'ensemble des Deployments et Pods dans tous les namespaces:

```
kubectl get deploy,po --all-namespaces
```

### 5. Suppression

La commande suivante permet de supprimer les namespaces *development* et *production*:

```
kubectl delete ns development production
```

Si nous listons les Deployments et Pods, nous pouvons voir que seuls les resources créées dans le namespace *default* sont présentes. Les ressources des namespaces *development* et *production* ont été supprimées avec la suppression de ces 2 namespaces.

La commande suivante permet de supprimer le deployment *www-0* existant dans le namespace *default*:

```
kubectl delete deploy www-0
```