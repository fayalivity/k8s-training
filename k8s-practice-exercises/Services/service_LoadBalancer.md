## Exercice

Dans cet exercice, vous allez créer un Pod et l'exposer à l'extérieur du cluster en utilisant un Service de type *LoadBalancer*.

Note: cet exercice ne peut être réalisé que si votre cluster est provisionné chez un cloud provider (Exoscale, DigitalOcean, GKE, EKS, ...).

### 1. Création d'un Pod

Créez un fichier *ghost.yaml* définissant un Pod ayant les propriétés suivantes:
- nom: *ghost*
- label associé au Pod: *app: ghost*
- nom du container: *ghost*
- image du container: *ghost:4*

Créez ensuite le Pod spécifié dans *ghost.yaml*.

### 2. Définition d'un service de type LoadBalancer

Créez un fichier *ghost-lb.yaml* définissant un service ayant les caractéristiques suivantes:
- nom: *ghost-lb*
- type: *LoadBalancer*
- un selector permettant le groupement des Pods ayant le label *app: ghost*.
- exposition du port *80*
- forward des requêtes vers le port *2368* des Pods sous-jacents (port d'écoute de l'application *ghost*)

Créez ensuite le Service spécifié dans *ghost-lb.yaml*

### 3. Adresse IP associée au service

Assurez-vous qu'une adresse IP externe est associée au Service *ghost-lb* (cela peut prendre quelques dizaines de secondes).

### 4. Accès au Service

Lancez un navigateur sur l'adresse IP externe du Service (il s'agit de l'adresse IP associé au LoadBalancer créé pour exposer le service à l'extérieur). Cela vous permettra d'accéder au Pod dans lequel tourne l'application *ghost*

![Service LoadBalancer](./images/service_LoadBalancer.png)

### 5. Cleanup

Supprimez l'ensemble des ressources créés dans cet exercice

---

## Correction

### 1. Création du Pod

La spécification du Pod est la suivante:

```
apiVersion: v1
kind: Pod
metadata:
  name: ghost
  labels:
    app: ghost
spec:
  containers:
  - name: ghost
    image: ghost:4
```

La commande suivante permet de créer le Pod:

```
kubectl apply -f ghost.yaml
```

### 2. Définition d'un Service de type LoadBalancer

La spécification du Service demandé est la suivante:

```
apiVersion: v1
kind: Service
metadata:
  name: ghost-lb
  labels:
    app: ghost
spec:
  selector:
    app: ghost
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 2368
```

La commande suivante permet de lancer le Service:

```
kubectl apply -f ghost-lb.yaml
```

### 3. Adresse IP associée au service

La commande suivante permet d'obtenir quelques informations relatives au service *ghost-lb* dont l'adresse IP externe associée:

```
kubectl get svc ghost-lb
```

Exemple de résultat dans lequel l'adresse IP externe est *194.182.168.11*, c'est donc l'adresse IP qui a été affectée au Load balancer (élément d'infrastructure créé par le cloud provider).

```
NAME       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
ghost-lb   LoadBalancer   10.99.246.92   194.182.168.11   80:32705/TCP   83s
```

Cette adresse IP peut donc être utilisée pour accéder à l'application qui tourne dans le Pod exposé par le service *ghost-lb*.

### 5. Cleanup

Les ressources peuvent être supprimées avec les commandes suivantes:

```
kubectl delete po/ghost
kubectl delete svc/ghost-lb
```
