Kind (Kubernetes in Docker) permet de déployer un cluster Kubernetes de façon à ce que chacun des nodes du cluster tourne dans un container Docker.

Pour l'utiliser il suffit simplement d'installer *Docker* ainsi que le binaire *kind*. Ce dernier peut-être installé via un package manager ou bien en récupérant le binaire déja buildée. Les différentes options d'installation sont présentés dans la [documentation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) 

## Les Commandes

Une fois installé, la liste des commandes disponibles peut être obtenue avec la commande suivante:

```
kind
```

Vous obtiendrez un résultat similaire à celui ci-dessous:

```
kind creates and manages local Kubernetes clusters using Docker container 'nodes'

Usage:
  kind [command]

Available Commands:
  build       Build one of [node-image]
  completion  Output shell completion code for the specified shell (bash, zsh or fish)
  create      Creates one of [cluster]
  delete      Deletes one of [cluster]
  export      Exports one of [kubeconfig, logs]
  get         Gets one of [clusters, nodes, kubeconfig]
  help        Help about any command
  load        Loads images into nodes
  version     Prints the kind CLI version

Flags:
  -h, --help              help for kind
      --loglevel string   DEPRECATED: see -v instead
  -q, --quiet             silence all stderr output
  -v, --verbosity int32   info log verbosity, higher value produces more output
      --version           version for kind

Use "kind [command] --help" for more information about a command.
```

## Création d'un cluster composé d'un seul node

Il suffit de lancer la commande suivante pour créer un cluster (seulement un node ici) en quelques dizaines de secondes:

```
kind create cluster --name k8s
```

Kind a automatiquement créé un context et l'a définit en tant que context courant de notre client *kubectl*.

```
$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO     NAMESPACE
*         kind-k8s     kind-k8s     kind-k8s
...
```

Nous pouvons alors lister les nodes du cluster (un seul ici)

```
kubectl get nodes
```

## HA Cluster

Kind permet également de mettre en place un cluster comportant plusieurs nodes, pour cela il faut utiliser un fichier de configuration. Par exemple, le fichier suivant (*config.yaml*) définit un cluster de 3 nodes: 1 master et 2 workers.

```
# config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

Pour mettre en place ce nouveau cluster, il suffit de préciser le fichier de configuration dans les paramètres de lancement de la commande de création.

```
kind create cluster --name k8s-2 --config config.yaml
```

Comme précédemment, Kind a automatiquement créé un context et l'a définit en tant que context courant.

```
$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO     NAMESPACE
          kind-k8s     kind-k8s     kind-k8s
*         kind-k8s-2   kind-k8s-2   kind-k8s-2
...
```

Nous pouvons dont directement lister les nodes, qui sont au nombre de 3 dans ce nouveau cluster:

```
kubectl get nodes
```

La commande suivante permet de lister les clusters présents:

```
kind get clusters
```

Celle-ci devrait renvoyer la liste suivante:

```
k8s
k8s-2
```

## Cleanup

Afin de supprimer un cluster créé avec *Kind*, il suffit de lancer la commande `kind delete cluster --name CLUSTER_NAME`.

Les commandes suivantes suppriment les 2 clusters créés précédemment:

```
kind delete cluster --name k8s
kind delete cluster --name k8s-2
```
