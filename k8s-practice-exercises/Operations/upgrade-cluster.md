Dans cet exercice, nous allons mettre à jour un cluster Kubernetes depuis la version 1.27.5 vers la version 1.28.2

## Prérequis

Avoir accès à un cluster dans la version 1.27.5 créé avec *kubeadm*.


Note: si vous souhaitez créer un cluster local 1.27.5 rapidement, vous pouvez lancer la commande suivante. Celle-ci crée des VMs Ubuntu en utilisant [Multipass](https://multipass.run) et installent Kubernetes avec Kubeadm*.

```
curl https://luc.run/k8s.sh | bash -s -- -v 1.27.5 -w 2
```

En quelques minutes vous aurez un cluster dans la version souhaitée, celui-ci étant constitué d'un node control plane (nommé *controlplane*) et de 2 nodes worker (nommés *worker1* et *worker2*).

Depuis votre machine locale vous pourrez alors configurer kubectl:

```
export KUBECONFIG=$PWD/kubeconfig.cfg
```

Assurez-vous ensuite que vous pouvez lister les nodes de votre cluster.

```
kubectl get nodes
```

## Mise à jour du node controlplane

La mise à jour commence par les nodes du controlplane (un seul dans le cadre de cet exercice)

### Mise à jour de kubeadm

Depuis un shell sur le node controlplane, lancez la commande suivante afin de lister les versions de *kubeadm* actuellement disponibles:

```
sudo apt update && sudo apt-cache policy kubeadm
```

Vous devriez obtenir un résultat similaire à celui-ci-dessous:

```
kubeadm:
  Installed: 1.27.5-00
  Candidate: 1.28.2-00
  Version table:
     1.28.2-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.28.1-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.28.0-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
     1.27.6-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
 *** 1.27.5-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main arm64 Packages
        100 /var/lib/dpkg/status
     1.27.4-00 500
```

Utilisez les commandes suivantes afin de mettre à jour *kubeadm* sur le node *controlplane*:

```
VERSION=1.28.2-00

sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=$VERSION
sudo apt-mark hold kubeadm
```

### Passage du node en mode Drain

En utilisant la commande suivanten, passez le node controlplane en *drain* de façon à ce que les Pods applicatifs (si il y en a) soient re-schédulés sur les autres nodes du cluster.

```
kubectl drain controlplane --ignore-daemonsets
```

### Upgrade du node

Depuis un shell root sur le node controlplane, vous pouvez à présent lancer la simulation de la mise à jour avec la commande suivante:

```
sudo kubeadm upgrade plan
```

Si tout s'est déroulé correctement vous devriez obtenir un résultat similaire à celui ci-dessous:

```
...
You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.28.2
...
```

Vous pouvez alors lancer la mise à jour:

```
sudo kubeadm upgrade apply v1.28.2
```

Après quelques minutes vous devriez obtenir le message suivant:

```
...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.28.2". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

### Passage du node en mode Uncordon

Modifiez le node controlplane de façon à le rendre de nouveau "schedulable".

```
kubectl uncordon controlplane
```

Note: dans le cas d'un cluster avec plusieurs node control plane, il faudrait également mettre à jour kubeadm sur les autres node puis lancer la commande suivante sur chacun d'entres eux:

```
kubeadm upgrade NODE_IDENTIFIER
```

### Mise à jour de kubelet et kubectl

Depuis un shell sur le node controlplane, utilisez la commande suivante afin de mettre à jour *kubelet* et *kubectl*:

```
VERSION=1.28.2-00

sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubectl
```

Redémarrez ensuite *kulelet*

```
sudo systemctl restart kubelet
```

Vérifiez que le node controlplane est à présent dans la nouvelle version:

```
$ kubectl get nodes
NAME            STATUS   ROLES           AGE     VERSION
controlplane    Ready    control-plane   7m53s   v1.28.2
worker1         Ready    <none>          7m6s    v1.27.5
worker2         Ready    <none>          6m52s   v1.27.5
```

## Mise à jour des nodes workers

Effectuez les actions suivantes sur chacun des nodes worker. Les instructions suivantes détaillent les actions à effectuer sur le premier worker, il faudra ensuite faire la même chose sur le second.

### Mise à jour de kubeadm

Depuis un shell sur *worker1*, lancez la commande suivante afin d'installer la version 1.28.2 du binaire *kubeadm*:

```
VERSION=1.28.2-00 

sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=$VERSION
sudo apt-mark hold kubeadm
```

### Passage du node en mode Drain

Depuis la machine locale, préparez le node pour le maintenance en la passant en mode *drain*, les Pods tournant sur le node seront reschédulés sur les autres nodes du cluster.

```
kubectl drain worker1 --ignore-daemonsets
```

### Mise à jour de la configuration de kubelet

Depuis le node *worker1* lancez la commande suivante afin de mettre à jour la configuration de *kubelet*.

```
sudo kubeadm upgrade node
```

Vous obtiendrez un résultat similaire à celui ci-dessous:

```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config2718687602/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
```

### Mise à jour de kubelet

Mettez ensuite à jour les binaires *kubelet* et *kubectl* à jour (toujours depuis un shell sur le node *worker1*):

```
VERSION=1.28.2-00

sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubectl
```

Puis redémarrez *kubelet* à l'aide de la commande suivante:

```
sudo systemctl restart kubelet
```

Vous pouvez ensuite rendre le node "schedulable":

```
kubectl uncordon worker1
```

Vérifiez alors que le premier worker est maintenant à jour.

```
$ kubectl get node
NAME            STATUS   ROLES           AGE   VERSION
controlplane    Ready    control-plane   13m   v1.28.2
worker1         Ready    <none>          13m   v1.28.2
worker2         Ready    <none>          12m   v1.27.5
```

Effectuez à présent ces mêmes actions sur le second worker.

## Test

Votre cluster doit maintenant avoir 3 nodes dans la version 1.28.2:

```
$ kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
controlplane    Ready    control-plane   16m   v1.28.2
worker1         Ready    <none>          15m   v1.28.2
worker2         Ready    <none>          15m   v1.28.2
```
