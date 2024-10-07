Dans cet exercice, vous allez ajouter une contrainte afin de déployer un Pod sur un node en particulier.

## 1. Définition d'un Pod Mysql

La spécification suivante définie un Pod contenant un container *mysql*.

```
apiVersion: v1
kind: Pod
metadata:
  name: db
spec:
  containers:
  - image: mysql:5.7
    name: mysql
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: mysqlpwd
    volumeMounts:
    - name: data
      mountPath: /var/lib/mysql
  volumes:
  - name: data
    emptyDir: {}
```

## 2. Ajout d'une contrainte de déploiement

Pour des raisons de performances, nous souhaitons déployer ce Pod sur un node contenant un disk SSD. Nous allons alors ajouter cette contrainte de déploiement via la clé *affinity* dans la spécification du Pod.

La spécification est modifiée de la façon suivante:

```
apiVersion: v1
kind: Pod
metadata:
  name: db
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  containers:
  - image: mysql:5.7
    name: mysql
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: mysqlpwd
    volumeMounts:
    - name: data
      mountPath: /var/lib/mysql
  volumes:
  - name: data
    emptyDir: {}
```

Copiez cette spécification dans le fichier *mysql.yaml*.

## 3. Déploiement du Pod

Lancez la commande suivante afin de créer le Pod:

```
kubectl apply -f mysql.yaml
```

puis vérifiez si le Pod a été correctement créé:

```
kubectl get po db
```

Vous devriez observer que le Pod reste dans l'état *Pending*. On peut en connaitre la raison en listant les évènements qui se sont déroulés suite à la demande de création:

```
$ kubectl describe po db
...
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  2s (x8 over 4m29s)  default-scheduler  0/3 nodes are available: 3 node(s) didn't match node selector.
```

Note: ce résultat est obtenu sur un cluster composé de 3 nodes

Etant donné qu'aucun node ne porte le label *disktype: ssd*, la contrainte de déploiement ne peut pas être respectée, le Pod ne peut pas être déployé.


## 4. Ajout d'un label sur l'un des nodes du cluster

Utilisez la commande suivante afin d'ajouter un label sur l'un des nodes du cluster.

Note: remplacez NODE_NAME par l'un des nodes de votre cluster:

```
kubectl label nodes NODE_NAME disktype=ssd
```

Après quelques secondes, lancez la commande suivante afin de vérifier le status du Pod

```
kubectl get po db
```

Vous devriez observer que le Pod est maintenant dans l'état *Running*.

Lancez un nouvelle fois le describe du Pod. Vous pourrez cette fois observer que le Pod a pu être schédulé sur le node sur lequel le label a été posé.

```
$ kubectl describe po db
...
Events:
  Type     Reason            Age                 From                       Message
  ----     ------            ----                ----                       -------
  Warning  FailedScheduling  59s (x18 over 11m)  default-scheduler          0/3 nodes are available: 3 node(s) didn't match node selector.
  Normal   Scheduled         55s                 default-scheduler          Successfully assigned default/db to NODE_NAME
  Normal   Pulling           51s                 kubelet, NODE_NAME  pulling image "mysql:5.7"
  Normal   Pulled            25s                 kubelet, NODE_NAME  Successfully pulled image "mysql:5.7"
  Normal   Created           25s                 kubelet, NODE_NAME  Created container
  Normal   Started           24s                 kubelet, NODE_NAME  Started container
```
