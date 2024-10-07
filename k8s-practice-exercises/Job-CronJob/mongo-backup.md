# Backup d'une base de données

Dans cet exercice, vous allez créer un *Job* qui servira à faire le dump d'une base de données *mongo*. Vous créerez ensuite un *CronJob* qui créera un dump à interval régulier.

## Exercice

### 1. Création d'un Pod Mongo

Dans un fichier *mongo-pod.yaml*, définissez la spécification d'un Pod nommé *db* et basé sur l'image *mongo:4.0* puis créez ensuite ce Pod.

Note: vous pouvez aussi créer ce Pod en utilisant la commande impérative ```kubectl run```

### 2. Exposition de la base Mongo

Dans un fichier *mongo-svc.yaml*, définissez la spécification d'un Service nommé *db*, de type *clusterIP* afin d'exposer le Pod précédent à l'intérieur du cluster. Créez ensuite ce Service.

Note: *MongoDB* écoute par défaut sur le port *27017*

Note: vous pouvez aussi créer ce Service en utilisant la commande impérative ```kubectl expose```

### 3. Ajout d'un label sur l'un des nodes du cluster

Dans les questions suivantes vous lancerez un Job pour effectuer un dump de la db créée précédement puis un Cronjob pour réaliser cette action à interval régulier. Afin de faire en sorte que les différents dump soient créés sur le système de fichiers d'un même node, ajouter le label *app=dump* sur l'un des nodes de votre cluster:

```
kubectl label node NODE_NAME app=dump
```

Note: dans un contexte de production, on s'assurerait que le dump soit envoyé directement sur un stockage externe (NFS, S3, ...).

### 4. Définition d'un Job pour effectuer le dump de la base de données

Dans un fichier *mongo-dump-job.yaml*, définissez le spécification d'un Job qui lance un Pod basé sur *mongo:4.0*.

Utilisez la propriété *nodeSelector* afin de déployer le Pod sur le node labelisé plus haut (vous pouvez utiliser la commande ```kubectl explain ...``` pour savoir comment définir cette propriété).

Le Pod lancé par le Job devra également définir un volume permettant de persister des données dans le répertoire */dump* du node sur lequel il tourne. Vous utiliserez pour cela l'instruction *volumes* dans la partie correspondant à la spécification du Pod:

```
volumes:
- name: dump
  hostPath:
    path: /dump
```

Le container mongo de ce Pod devra monter ce volume dans son répertoire */dump*. Vous utiliserez pour cela l'instruction *volumeMounts* dans la spécification du container *mongo*:

```
volumeMounts:
- name: dump
  mountPath: /dump
```

De plus, vous ferez en sorte que le container de ce Pod lance la commande suivante afin de créer le fichier */dump/db.gz* contenant le dump de la base de données.

```
/bin/bash -c mongodump --gzip --host db --archive=/dump/db.gz
```

Note: cette commande utilise le binaire *mongodump* qui est présent dans l'image *mongo:4.0*. Le container se connectera au service *db* que vous avez lancé précédemment.

Lancez ensuite ce Job puis vérifiez que le Pod lancé par ce Job a tourné correctement.


### 5. Définition d'un CronJob pour effectuer le dump de la base de données à intervalle régulier

Dans un fichier *mongo-dump-cronjob.yaml*, définissez le spécification d'un CronJob qui lance un dump de mongo toutes les minutes.

Utilisez la propriété *nodeSelector* afin de déployer le Pod sur le node labelisé plus haut (vous pouvez utiliser la commande ```kubectl explain ...``` pour savoir comment définir cette propriété).

Afin de conserver les différents dump, vous ferez en sorte que le container du Pod lance la commande suivante (celle-ci ajoute un timestamp dans le nom du fichier de dump généré):

```
/bin/bash -c mongodump --gzip --host db --archive=/dump/$(date +"%Y%m%dT%H%M%S")-db.gz
```

Lancez ensuite ce CronJob.

### 6. Vérification des dumps

Lancez un Pod *test* en vous assurant qu'il soit schédulé sur le node ayant le label *app: dump* et qu'il ait accès au répertoire */dump* de ce node.

Depuis un shell dans ce Pod vérifiez que les dumps ont bien été créés.

### 7. Vérification des dumps (autre méthode)

Utilisez la commande ```kubectl debug``` pour lancer un pod *alpine* sur l'un des nodes de votre cluster.

### 8. Cleanup

Supprimez ensuite les Job et CronJob précédents.

---

## Correction

### 1. Création d'un Pod Mongo

La spécification suivante définit le Pod *db* basé sur *mongo:4.0*.

```
apiVersion: v1             
kind: Pod                  
metadata:
  name: db
  labels:
    app: db
spec:
  containers:
  - name: mongo
    image: mongo:4.0
```

Copiez cette spécification dans *mongo-pod.yaml* et lancez ce Pod avec la commande:

```
kubectl apply -f mongo-pod.yaml
```

Note: vous pouvez également utiliser la commande impérative suivante pour créer le Pod *db*

```
kubectl run db --image=mongo:4.0
```

### 2. Exposition de la base Mongo

La spécification suivante définit le Service *db* de type *ClusterIP*. Ce service permet d'exposer le Pod précédent à l'intérieur du cluster.

```
apiVersion: v1
kind: Service
metadata:
  name: db
spec:
  selector:
    app: db
  type: ClusterIP
  ports:
  - port: 27017
```

Copiez cette spécification dans *mongo-svc.yaml* et lancez ce Service avec la commande:

```
kubectl apply -f mongo-svc.yaml
```

Note: vous pouvez également créer ce Service avec la commande impérative suivante:

```
kubectl expose pod/db --port 27017 --target-port 27017
```

### 4. Définition d'un Job pour effectuer le dump de la base de données

La spécification suivante définit un Job qui effectue le dump de la base de données.

```
apiVersion: batch/v1
kind: Job
metadata:
  name: dump
spec:
  template:
    spec:
      restartPolicy: Never
      nodeSelector:
        app: dump
      containers:
      - name: mongo
        image: mongo:4.0
        command:
        - /bin/bash
        - -c
        - mongodump --gzip --host db --archive=/dump/db.gz
        volumeMounts:
        - name: dump
          mountPath: /dump
      volumes:
      - name: dump
        hostPath:
          path: /dump
```

Copiez cette spécification dans *mongo-dump-job.yaml* et lancez ce Job avec la commande:

```
kubectl apply -f mongo-dump-job.yaml
```

Après quelques secondes on peut vérifier que le Pod lancé par le Job est dans l'état *Completed*:

```
$ kubectl get po
NAME         READY   STATUS      RESTARTS   AGE
dump-r5jg6   0/1     Completed   0          32s
```

Nous pouvons également regarder les logs du Pods afin d'avoir la confirmation que le dump a été effectué correctement:

```
$ kubectl logs dump-r5jg6
2022-05-24T20:23:23.865+0000	writing admin.system.version to archive '/dump/db.gz'
2022-05-24T20:23:23.870+0000	done dumping admin.system.version (1 document)
```

### 5. Définition d'un CronJob pour effectuer le dump de la base de données à intervalle régulier

La spécification suivante définit un CronJob qui effectue le dump de la base de données, accessible via le service nommé *db*, toutes les minutes.

```
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dump
spec:
  schedule: "* * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          nodeSelector:
            app: dump
          containers:
          - name: mongo
            image: mongo:4.0
            command:
            - /bin/bash
            - -c
            - mongodump --gzip --host db --archive=/dump/$(date +"%Y%m%dT%H%M%S")-db.gz
            volumeMounts:
            - name: dump
              mountPath: /dump
          restartPolicy: OnFailure
          volumes:
          - name: dump
            hostPath:
              path: /dump
```

Copiez cette spécification dans *mongo-dump-cronjob.yaml* et lancez ce CronJob avec la commande:

```
kubectl apply -f mongo-dump-cronjob.yaml
```

### 6. Vérification des dump

La commande suivante lance le Pod *test* demandé:

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test
spec:
  nodeSelector:
    app: dump
  containers:
  - name: test
    image: alpine:3.15
    command:
    - "sleep"
    - "10000"
    volumeMounts:
    - name: dump
      mountPath: /dump
  volumes:
  - name: dump
    hostPath:
      path: /dump
EOF
```

Lancez un shell interactif dans le container du pod *test*:

```
kubectl exec -ti test -- sh
```

Depuis ce shell, vous pourrez observer les dumps créés

```
# ls /dump
20220524T202900-db.gz  20220524T203000-db.gz  20220524T203100-db.gz  db.gz
```

### 7. Vérification des dumps (autre méthode)

La commande suivante permet de lancer un Pod de debug dont l'unique container *alpine* sera lancé dans les namespaces pid et network du node NODE_NAME. Le système de fichiers du node sera automatiquement monté dans le répertoire */host* du container: 

```
kubectl debug node/NODE_NAME -it --image=alpine
```

Les dumps sont donc présents dans */host/dump* depuis le container *alpine*.

### 8. Cleanup

La commande suivante permet de supprimer les différentes ressources créées:

```
kubectl delete job/dump cj/dump po/test po/db svc/db
```