Dans cet exercice, vous allez mettre en place un cluster Kubernetes à l'aide de l'utilitaire *kubeadm*. Afin de simplifier le provisonning des machines virtuelles, nous utiliserons [Multipass](https://multipass.run) un outil qui permet de créer des machines virtuelles très simplement.

## Création des VMs

Installez tout d'abord [Multipass](https://multipass.run) (celui-ci est disponible pour Windows, Linux et MacOS) puis lancez les commandes suivantes pour créer 2 machines virtuelles nommées *controlplane* et *worker*

```
multipass launch -n controlplane -m 2G -c 2 -d 10G
multipass launch -n worker -m 2G -c 2 -d 10G
```

Note: par défaut Multipass crée des VMs en limitant leurs ressources à 1 cpu, 1G RAM et 5G de disque. Les commandes ci-dessus donnent un peu plus de ressources que les valeurs par défaut.

## Installation de Kubectl

Assurez-vous d'avoir installé *kubectl* sur la machine depuis laquelle vous avez lancé les commandes Multipass. *kubectl*  permet de communiquer avec un cluster Kubernetes depuis la ligne de commande.
Note: vous pouvez vous reporter à l'exercice [installation de kubectl](https://gitlab.com/lucj/k8s-exercices/-/blob/master/Installation/kubectl.md) pour l'installation de *kubectl*.

## Initialisation du cluster

Une fois les VMs créées, vous allez initialiser le cluster.

Lancez tout d'abord un shell sur *controlplane*:

```
multipass shell controlplane
```

Depuis ce shell lancez la commande suivante, celle-ci installe les dépendances nécessaires (container runtime et quelques packages)

```
curl -sSL https://luc.run/kubeadm/controlplane.sh | VERSION=1.27.5 sh
```

Toujours depuis le shell sur la VM *controlplane* lancez ensuite la commande qui initialize le cluster:

```
sudo kubeadm init
```

Après quelques dizaines de secondes, vous obtiendrez alors une commande qui vous servira, par la suite, à ajouter un node worker au cluster qui vient d'être créé.

Exemple de commande retournée (les tokens que vous obtiendrez seront différents):

```
sudo kubeadm join 192.168.64.40:6443 --token xrtqvq.9zmmzjx16b4jc4q8 --discovery-token-ca-cert-hash sha256:fabe1bbc0264b36a624b0c7284fe58151dad0640c81bff9a9f0e33fecd377e1a
```

Récupérez le fichier kubeconfig pour l'utilisateur courant (*ubuntu*):

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Ajout d'un node worker

Une fois le cluster initialisé, vous allez ajouter un node worker.

Lancez tout d'abord un shell sur *worker*:

```
multipass shell worker
```

Depuis ce shell lancez la commande suivante, celle-ci installe les dépendances nécessaires sur le worker:

```
curl -sSL https://luc.run/kubeadm/worker.sh | VERSION=1.27.5 sh
```

Lancez ensuite la commande retournée lors de l'étape d'initialisation (*sudo kubeadm join ...*) afin d'ajouter le node *worker* au cluster.

```
sudo kubeadm join 192.168.64.40:6443 --token xrtqvq.9zmmzjx16b4jc4q8 --discovery-token-ca-cert-hash sha256:fabe1bbc0264b36a624b0c7284fe58151dad0640c81bff9a9f0e33fecd377e1a
```

Note: si vous avez perdu la commande d'ajout de node, vous pouvez la générer avec la commande suivante (à lancer depuis le node controlplane)

```
sudo kubeadm token create --print-join-command
```

Après quelques dizaines de secondes, vous obtiendrez rapidement une confirmation indiquant que la VM *worker* fait maintenant partie du cluster::

```
This node has joined the cluster
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.
...
```

## Etat du cluster

Listez à présent les nodes du cluster avec la commande suivante depuis un shell sur le node *controlplane*:

```
ubuntu@controlplane:~$ kubectl get nodes
NAME           STATUS     ROLES           AGE   VERSION
controlplane   NotReady   control-plane   93s   v1.27.5
worker         NotReady   <none>          11s   v1.27.5
```

Les nodes sont dans l'état *NotReady*, cela vient du fait qu'aucun plugin network n'a été installé pour le moment.

## Plugin network

Afin que le cluster soit opérationnel il est nécessaire d'installer un plugin network. Plusieurs plugins sont disponibles (Cilium, Calico, WeaveNet, Flannel, …), chacun implémente la spécification CNI (Container Network Interface) et permet notamment la communication entre les différents Pods du cluster.

Dans cet exercice, vous allez installer le plugin Cilium. Utilisez pour cela les commandes suivantes:

```
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-$OS-$ARCH.tar.gz{,.sha256sum}
sudo tar xzvfC cilium-$OS-$ARCH.tar.gz /usr/local/bin
cilium install
```

Note: l'article suivant effectue un benchmark des différentes solutions [https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-updated-august-2020-6e1b757b9e49](https://itnext.io/benchmark-results-of-kubernetes-network-plugins-cni-over-10gbit-s-network-updated-august-2020-6e1b757b9e49)


Après quelques secondes, les nodes apparaitront dans l'état *Ready*

```
ubuntu@controlplane:~$ kubectl get nodes
NAME           STATUS   ROLES           AGE    VERSION
controlplane   Ready    control-plane   3m7s   v1.27.5
worker         Ready    <none>          105s   v1.27.5
```

Le cluster est prêt à être utilisé.

## Récupération du context

Afin de pouvoir dialoguer avec le cluster via le binaire *kubectl* que vous avez installé sur votre machine locale, il est nécessaire de récupérer le fichier de configuration généré lors de l'installation.

Pour cela, il faut récupérer le fichier */etc/kubernetes/admin.conf* présent sur le node controlplane et le copier sur votre machine locale.

Avec Multipass vous pouvez récupérer le fichier de configuration avec la commande suivante (il sera alors sauvegardé dans le fichier *kubeconfig* du répertoire courant):

```
multipass exec controlplane -- sudo cat /etc/kubernetes/admin.conf > kubeconfig
```

Une fois que le fichier est présent en local, il faut simplement indiquer à *kubectl* ou il se trouve en positionnant la variable d'environnement *KUBECONFIG*:

```
export KUBECONFIG=$PWD/kubeconfig
```

Listez une nouvelle fois les nodes du cluster.

```
$ kubectl get nodes
NAME           STATUS   ROLES           AGE     VERSION
controlplane   Ready    control-plane   3m39s   v1.27.5
worker         Ready    <none>          2m17s   v1.27.5
```

Vous pouvez à présent communiquer avec le cluster depuis votre machine locale et non depuis une connexion ssh sur le node controlplane.

## En résumé

Le cluster que vous avez mis en place dans cet exercice contient un node controlplane et 1 node worker. Il est également possible avec kubeadm de mettre en place un cluster HA avec plusieurs nodes controlplane en charge de la gestion du cluster.