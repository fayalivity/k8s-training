Dans cet exercice, vous allez manipuler un DaemonSet.  

Dans le fichier *log-ds.yaml*, créez une spécification de DaemonSet avec les caractéristiques suivantes:
- le DaemonSet à le nom *log*
- chaque Pod a un seul container basé sur l'image *alpine*
- chaque container a accès au répertoire */var/log/* sur le système de fichier du node sur lequel il tourne, ce répertoire étant monté à l'emplacement */var/log/node* dans le système de fichier du container
- chaque container écrit le contenu des fichiers *.log (situés dans */var/log/node*) dans sa sortie standard 

Créez le DaemonSet définit dans cette spécification et regardez les logs des Pods créés.

Note: vous pourrez utiliser la documentation suivante pour vous aider: [https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/).

Supprimez ensuite le DaemonSet.

<details>
  <summary markdown="span">Solution</summary>

- La spécification suivante définit le DaemonSet *log* dont chaque Pod a un seul container basé sur l'image *alpine*:

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log
spec:
  selector:
    matchLabels:
      app: log
  template:
    metadata:
      labels:
        app: log
    spec:
      containers:
      - name: log
        image: alpine
```

Note: ne lancez pas ce DaemonSet pour le moment, cela donnerait une erreur car le container alpine serait redémarré en continu

- Nous ajoutons la définition d'un volume *hostPath* permettant d'accéder au répertoire */var/log* de la machine hôte et nous mettons son contenu à disposition dans le répertoire */var/log/node* du container:

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log
spec:
  selector:
    matchLabels:
      app: log
  template:
    metadata:
      labels:
        app: log
    spec:
      containers:
      - name: log
        image: alpine
        volumeMounts:
        - name: varlog
          mountPath: /var/log/node
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

- Nous ajoutons une commande pour faire en sorte que le container écrive le contenu des fichiers *.log, présents dans le répertoire */var/log/nodes*, dans sa sortie standard:

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log
spec:
  selector:
    matchLabels:
      app: log
  template:
    metadata:
      labels:
        app: log
    spec:
      containers:
      - name: log
        image: alpine
        command: ["/bin/sh", "-c"]
        args: ["tail -f /var/log/node/*.log"]
        volumeMounts:
        - name: varlog
          mountPath: /var/log/node
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

Une fois sauvegardée dans le fichier *log-ds.yaml* nous pouvons créer ce DaemonSet:

```
kubectl apply -f log-ds.yaml
```

Nous listons les Pods associés:

```
kubectl get pods -l app=log
```

Nous pouvons alors voir les logs de l'un des Pods associés au DaemonSet:

```
kubectl logs ds/log
```

Dans un contexte de production, un DaemonSet pourrait être utilisé pour déployer des Pods qui vont lire les logs de chacun des nodes et les envoyer sur une solution de gestion de logs centralisée (telle que ElasticSearch, Splunk, ...)

Vous pouvez ensuite supprimer ce DaemonSet:

```
kubectl delete ds log
```

</details>