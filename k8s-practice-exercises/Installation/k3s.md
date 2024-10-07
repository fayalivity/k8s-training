K3s est une distribution Kubernetes très light (5 ‘s’ de moins que dans k8s :) ). C'est une distribution certifiée, très adaptée pour l'IoT, l'Edge computing, ...

Sur Windows, MacOS ou Linux, K3s peut facilement être installé dans une machine virtuelle. Nous utiliserons ici [Multipass](https://multipass.run) un outils très pratique qui permet de lancer facilement des machines virtuelles Ubuntu sur Mac, Linux, ou Windows.

Note: vous pouvez vous reporter à l'exercice précédent pour l'installation de Multipass et l'illustration de différentes commandes.

## Cluster avec un seul node

### 1. Création d'une VM Ubuntu

Utilisez la commande suivante pour créer une VM Ubuntu 18.04, nommée *k3s-1*, avec Multipass:

```
multipass launch --name k3s-1
```

Récupérez ensuite l'adresse IP de la VM:

```
IP=$(multipass info k3s-1 | grep IP | awk '{print $2}')
```

### 2. Installation de k3s

Lancez l'installation de la distribution k3s dans la VM que vous venez de créer (celle-ci devrait prendre une trentaine de secondes !)

```
multipass exec k3s-1 -- bash -c "curl -sfL https://get.k3s.io | sh -"
```

Note: la commande `curl -sfL https://get.k3s.io | sh -` provient de la documentation officielle de [k3s](https://k3s.io)

### 3. Fichier de configuration

Récupérez, sur votre machine locale, le fichier de configuration généré lors de l'installation de Kubernetes:

```
multipass exec k3s-1 sudo cat /etc/rancher/k3s/k3s.yaml > k3s.cfg.tmp
```

Dans ce fichier, il est nécessaire de remplacer l'adresse IP locale (127.0.0.1) par l'adresse IP de la machine virtuelle dans laquelle tourne kubernetes:

```
cat k3s.cfg.tmp | sed "s/127.0.0.1/$IP/" > k3s.cfg
```

Positionnez ensuite la variable d'environnement *KUBECONFIG* de façon à ce qu'elle pointe vers le fichier de configuration récupéré précédemment:

```
export KUBECONFIG=$PWD/k3s.cfg
```

Cette variable d'environnement permet de configurer le binaire *kubectl* afin que celui-ci puisse communiquer avec le cluster.

### 4. Test

Le cluster est maintenant prêt à être utilisé:

```
kubectl get nodes
```

## Cluster multi-nodes

Il est très simple d'ajouter des nodes à un cluster k3s. Dans l'exemple ci-dessous, nous allons provisionner 2 VMs supplémentaires avec Multipass et les joindre en tant que *workers* au cluster mis en place précédemment.

### 1. Création de VMs supplémentaires

```
for node in k3s-2 k3s-3;do
  multipass launch -n $node
done
```

### 2. Ajout de nodes

Dans un premier temps il est nécessaire de récupérer, depuis le node master *k3s-1*, un token créé lors de l'installation. Ce token sera utilisé dans la suite pour ajouter un node au cluster:

```
TOKEN=$(multipass exec k3s-1 sudo cat /var/lib/rancher/k3s/server/node-token)
```

Les nodes *k3s-2* et *k3s-3* peuvent ensuite être ajoutés facilement avec les commandes suivantes:

Note: la variable d'environment *IP* a été définie précédemment, elle contient l'adresse IP de la VM *k3s-1*

```
# Join node2
multipass exec k3s-2 -- \
bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$IP:6443\" K3S_TOKEN=\"$TOKEN\" sh -"

# Join node3
multipass exec k3s-3 -- \
bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$IP:6443\" K3S_TOKEN=\"$TOKEN\" sh -"
```

### 3. Test

Nous pouvons alors lister les nodes du cluster et vérifier que celui-ci est maintenant composé d'un master et de 2 workers:

```
kubectl get nodes
```

Le cluster est prêt à être utilisé.