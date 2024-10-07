## Exercice

Dans cet exercice, vous allez créer un Deployment et l'exposer à l'extérieur du cluster via un service de type NodePort.

### 1. Création d'un Deployment

Créez un fichier *ghost_deployment.yaml* définissant un Deployment ayant les propriétés suivantes:
- nom: *ghost*
- nombre de replicas: 3
- définition d'un selector sur le label *app: ghost*
- spécification du Pod:
  * label *app: ghost*
  * un container nommé *ghost* basé sur l'image *ghost:4* et exposant le port *2368*

Créez ensuite la ressource spécifiée.

### 2. Status du Deployment

A l'aide de *kubectl*, examinez le status du Deployment *ghost*.

A partir de ces informations, que pouvez-vous dire par rapport au nombre de Pods gérés par ce Deployment ?

### 3. Status des Pods associés

A l'aide de *kubectl*, lister les Pods associés à ce Deployment.

### 4. Exposition des Pods du Deployment

Créez un Service permettant d'exposer les Pods du Deployment à l'extérieur du cluster

Conseils:

- vous pourrez commencer par créer une spécification pour le Service, en spécifiant que le *selector* doit permettre de regrouper les Pods ayant le label *app: ghost*.

- utilisez un service de type *NodePort*, vous pourrez par exemple le publier sur le port *31001* des nodes du cluster

- le container basé sur l'image *ghost:4* tourne sur le port *2368*, ce port devra donc être référencé en tant que *targetPort* dans la spécification du Service.

Note: n'hésitez pas à vous reporter à l'exercice sur les Services de type NodePort que nous avons vu précédemment

Une fois le service créé, vous pourrez accéder à l'interface de l'application *ghost* sur *http://IP:31001* ou IP est l'adresse IP d'une machine du cluster Kubernetes.

Note: vous pouvez récupérer les IPs des machines de votre cluster avec la commande `$ kubectl get nodes -o wide`

![Interface de l'application ghost](./images/deployment_ghost.png)

### 5. Cleanup

Supprimez le Deployment ainsi que le Service créés précédemment.

---

## Correction

### 1. Création d'un Deployment

La spécification, définie dans le fichier *ghost_deployment.yaml* est la suivante:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ghost
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ghost
  template:
    metadata:
      labels:
        app: ghost
    spec:
      containers:
      - name: ghost
        image: ghost:4
        ports:
        - containerPort: 2368
```

La commande suivante permet de créer le Deployment

```
kubectl apply -f ghost_deployment.yaml
```

### 2. Status du Deployment

La commande suivante permet d'obtenir le status du Deployment

```
$ kubectl get deploy
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ghost   3/3     3            3          51s
```

### 3. Status des Pods associés

La commande suivante permet de lister les Pods qui tournent sur le cluster

```
$ kubectl get po
NAME                    READY   STATUS    RESTARTS   AGE
ghost-548879c755-7kmpz   1/1     Running   0          68s
ghost-548879c755-m5pjt   1/1     Running   0          68s
ghost-548879c755-nwl9l   1/1     Running   0          68s
```

On voit que les 3 Pods relatifs au Deployment *ghost* sont listés. Ils sont tous les 3 actifs.

### 4. Exposition des Pods du Deployment

Dans un fichier *ghost_service.yaml* nous définissons la spécification suivante:

```
apiVersion: v1
kind: Service
metadata:
  name: ghost
spec:
  selector:
    app: ghost
  type: NodePort
  ports:
  - port: 80
    targetPort: 2368
    nodePort: 31001
```

On crée ensuite le Service:

```
kubectl apply -f ghost_service.yaml
```

### 5. Cleanup

Supprimez le Deployment et le Service:

```
kubectl delete deploy/ghost
kubectl delete svc/ghost
```
