Dans cet exercice, vous allez créer un Deployment et effectuer un rolling update.

### 1. Création d'un Deployment

A l'aide de la commande `kubectl create`, créez un Deployment
- nommé *www*
- définissant un Pod basé sur l'image *nginx:1.16*

Note: la commande `kubectl create` fait partie des commandes dites impératives, elle permet de créer un Deployment sans passer par un fichier de spécification en yaml. Cette approche permet d'aller vite, elle est a utiliser dans un contexte de développement ou de debugging. La commande `kubectl create` permet de spécifier le nombre de réplicas à la création d'un Deployment (via l'option --replicas), par défaut un seul réplica de Pod sera créé.

### 2. Scaling

Changez ce nombre de replicas de façon à en avoir 3.

Note: pour cela vous pourrez avoir besoin de la commande `$ kubectl scale ...`. L'aide en ligne `$ kubectl scale --help` donne quelques exemples d'utilisation.

### 3. Liste des ressources

Listez les ressources créées par la commande précédente (Deployment, ReplicaSet, Pod).

### 4. Mise à jour de l'image

Mettez l'image nginx à jour avec le version *nginx:1.16-alpine*

Note: spécifiez l'option *--record*  afin de conserver l'historique de la mise à jour

### 5. Liste des ressources

Une nouvelle fois, listez les ressources.

Que constatez vous ?

### 6. Historique des mises à jour

Listez les mises à jour (= révisions) du Deployment.

Note: utilisez la commande `kubectl rollout...`

### 7. Effectuez un rollback

Faites un rollback et vérifier que le Deployment est maintenant basé sur la version précédente de l'image (*nginx:1.16*)

### 8. Cleanup

Supprimez le Deployment *www*

---

## Correction

### 1. Création d'un Deployment

Le Deployment peut être créé avec la commande suivante:

```
kubectl create deploy www --image nginx:1.16
```

### 2. Scaling

La commande suivante permet de modifier le nombre de réplicas du Deployment

```
kubectl scale deploy/www --replicas 3
```

### 3. Liste des ressources

La commande suivante permet de lister les Deployment, ReplicaSet et Pod.

On utilise les raccourcis suivants:
- Deployment => deploy
- ReplicaSet => rs
- Pod        => po

```
$ kubectl get deploy,rs,pod
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/www   3/3     3            3           20s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/www-84b9d66d8d   3         3         3       20s

NAME                       READY   STATUS    RESTARTS   AGE
pod/www-84b9d66d8d-5d8wk   1/1     Running   0          20s
pod/www-84b9d66d8d-966ks   1/1     Running   0          15s
pod/www-84b9d66d8d-crf87   1/1     Running   0          15s
```

Les commandes de la première question ont créé:
- 1 Deployment
- 1 ReplicaSet
- 3 Pods

Le ReplicaSet assure que les 3 Pods sont actifs.

### 4. Mise à jour de l'image

La commande suivante permet de mettre à jour l'image avec la version *nginx:1.16-alpine*.

```
kubectl set image deploy/www nginx=nginx:1.16-alpine --record
```

Note: lorsque nous avons créé le Deployment avec la commande `kubectl create deploy`, nous n'avons pas utilisé de spécification détaillée et n'avons donc pas donné de nom au container du Pod. Cependant, le nom *nginx* a automatiquement été utilisé pour le nom du container, celui-ci provient de l'image utilisée. C'est donc le nom de ce container qui est utilisé dans la partie `nginx=nginx:1.16` de la commande ci dessus.

### 5. Liste des ressources

Nous utilisons la même commande que dans la question 2:

```
$ kubectl get deploy,rs,pod
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/www   3/3     3            3           79s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/www-5fd6c8cc68   3         3         3       38s
replicaset.apps/www-84b9d66d8d   0         0         0       80s

NAME                       READY   STATUS    RESTARTS   AGE
pod/www-5fd6c8cc68-7csqg   1/1     Running   0          32s
pod/www-5fd6c8cc68-d6jtc   1/1     Running   0          38s
pod/www-5fd6c8cc68-j9hmn   1/1     Running   0          35s
```

Nous pouvons voir ici qu'il y a maintenant 2 ReplicaSet:
- un pour la gestion des Pods utilisant l'image *nginx:1.16*. Celui-ci n'est plus actif, comme le montre la valeur *0* des champs *DESIRED*, *CURRENT* et *READY* relatifs aux Pods gérés par le ReplicaSet
- un second qui a été créé lors de la mise à jour de l'image, il gère 3 Pods, chacun ayant un container basé sur l'image *nginx:1.16-alpine*

### 6. Historique des mises à jour

La commande suivante permet de voir la commande associée à la mise à jour du Deployment:

```
$ kubectl rollout history deploy/www
deployment.apps/www
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deploy/www nginx=nginx:1.16-alpine --record=true
```

### 7. Rollback

La commande suivante permet de faire un rollback et donc de revenir à un Pod basé sur l'image *nginx:1.16*

```
kubectl rollout undo deploy/www
```

On peut alors vérifier la version de l'image qui est utilisée dans la spécification du Deployment:

```
$ kubectl get deploy/www -o jsonpath='{.spec.template.spec.containers[0].image}'
nginx:1.16
```

### 8. Cleanup

Le Deployment et les ressources associées (ReplicaSet et Pods) peuvent être supprimées avec la commande suivante:

```
kubectl delete deploy www
```
