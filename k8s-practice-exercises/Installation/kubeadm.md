Suivez les étapes suivantes afin de créer un cluster à l'aide de *kubeadm*. Ce cluster sera constitué de 3 nodes, un node *controlplane* et 2 nodes *worker*.
1. Pre-requisites

Assurez-vous d'avoir accès à 3 machines virtuelles ayant les noms suivants:

- *controlplane*
- *worker1*
- *worker2*

Ces VMs doivent avoir au moins 2 vCPU et 2G de mémoire.

Pour les prochaines étapes, il est recommandé d'avoir 4 terminaux ouverts, un sur la machine hôte et un sur chaque VM.

2. Installation des dépendences

Utilisez la commande suivante afin d'installer les dépendances (le container runtime et quelques librairies) sur les différents nodes:

Note: les scripts *controlplane.sh* et *worker.sh* utilisés ci-dessous installent les dépendances en suivant les instructions indiquées dans la documentations de kubeadm.

- depuis un shell sur le node *controlplane*:

```
curl https://luc.run/kubeadm/controlplane.sh | sh
```

- depuis un shell sur le node *worker1*:

```
curl https://luc.run/kubeadm/worker.sh | sh
```

- depuis un shell sur le node *worker2*:

```
curl https://luc.run/kubeadm/worker.sh | sh
```

3. Initialisation du cluster

Initialisez le cluster depuis le node *controlplane*:

```
sudo kubeadm init
```

Après quelques dizaines de secondes l'initialisation sera terminée. Vous obtiendrez alors la commande que vous utiliserez au point 4 pour ajouter des nodes au cluster. Cette commande est similaire à celle ci-dessous:

```
kubeadm join 10.96.217.40:6443 --token ucvk2f.vsj6636g36lwwu6x \
	--discovery-token-ca-cert-hash sha256:d772772e54e30d1ae2bc80590d43f3fdf73e1e505b2d551053489786c3338464
```

Toujours depuis le shell sur le node *controlplane*, récupérez le fichier kubeconfig d'admin et sauvegardez le dans *$HOME/.kube/config*:

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

4. Ajout des nodes workers:

Lancez la commandes "sudo kubeadm join..." (commande obtenue à l'étape précédente) sur les nodes *worker1* et *worker2* afin de les ajouter au cluster:

Note: si vous avez perdue cette commande, vous pouvez l'obtenir de la façon suivante: ```sudo kubeadm token create --print-join-command```

Une fois les nodes ajoutés, retournez sur le node *controlplane* et listez les nodes du cluster. Vous verrez que celui-ci contient 3 nodes:

```
$ kubectl get no
NAME            STATUS     ROLES           AGE     VERSION
controlplane    NotReady   control-plane   7m7s    v1.28.8
worker1         NotReady   <none>          4m54s   v1.28.8
worker2         NotReady   <none>          4m14s   v1.28.8
```

5. Network plugin

Le résultat précédent montre que le cluster n'est pas encore prêt à être utilisé. Vous devez tout d'abord installer un plugin network. Dans cet exercice vous allez installer *Cilium* mais un autre plugin pourrait être utilisé à la place.

Pour installer *Cilium*, lancez la commande suivante sur le node *controlplane*:

```
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-$OS-$ARCH.tar.gz{,.sha256sum}
sudo tar xzvfC cilium-$OS-$ARCH.tar.gz /usr/local/bin
cilium install
```

Cela prendra quelques dizaines de secondes pour que votre cluster soit prêt.

```
$ kubectl get no
NAME            STATUS   ROLES           AGE     VERSION
controlplane    Ready    control-plane   10m     v1.28.8
worker1         Ready    <none>          8m22s   v1.28.8
worker2         Ready    <none>          7m42s   v1.28.8
```

6. Récupération du fichier kubeconfig sur votre machine locale

Copiez le fichier kubeconfig situé sur le node *controlplane* à l'emplacement */etc/kubernetes/admin.conf*, dans le fichier *$HOME/kubeadm.kubeconfig* sur votre machine locale (ou votre machine d'admin).

Ensuite, indiquez à votre client *kubectl* le chemin d'accès à ce fichier:

```
export KUBECONFIG=$HOME/kubeadm.kubeconfig
```

Vous pouvez maintenant communiquer avec le cluster depuis votre machine locale sans avoir à vous connecter en ssh sur le node controlplane:

```
$ kubectl get no
NAME            STATUS   ROLES           AGE   VERSION
controlplane    Ready    control-plane   13m   v1.28.8
worker1         Ready    <none>          10m   v1.28.8
worker2         Ready    <none>          10m   v1.28.8
```