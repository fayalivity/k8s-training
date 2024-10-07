## Objectif

Dans cet exercice, nous allons utiliser *Rook* pour mettre en place un cluster de stockage *Ceph* dans un cluster [K3s](https://k3s.io). Nous utiliserons ensuite le stockage block de Ceph pour persister les données d'une application basée sur [Ghost](https://ghost.org), une plateforme de blogging open source.

## Prérequis

Assurez-vous que les composants suivants sont installés sur votre machine locale:

- [Vagrant](https://vagrantup.com)
- [VirtualBox](https://virtualbox.org)
- [kubectl](https://gitlab.com/lucj/k8s-exercices/-/blob/master/Installation/kubectl.md)

## Mise en place du cluster

Nous illustrerons cet exercice en utilisant une seule VM provisionnée en local sur l'hyperviseur [VirtualBox](https://virtualbox.org) en utilisant l'utilitaire [Vagrant](https://vagrantup.com).

Le fichier *Vagrantfile* ci dessous définit:
- la configuration de la VM qui sera créée:
  * la distribution Linux utilisée
  * son adresse IP (192.168.33.10)
  * la RAM allouée (2G)
  * l'ajout d'un disque supplémentaire d'une capacité de 10G
- la mise en place de K3s et la récupération du fichier kubeconfig associé

:fire: Le point important ici est d'attacher un disque non formaté (raw device) à la VM qui sera créée. Rook utilisera ce disque dans la suite pour la persistance des données du cluster Ceph qui sera mis en place.


```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.disk :disk, size: "10GB", name: "osd"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
  config.vm.provision "shell", inline: <<-SHELL
    curl https://get.k3s.io | sh
    sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/kubeconfig.k3s
    sed -i "s/127.0.0.1/192.168.33.10/" /vagrant/kubeconfig.k3s
  SHELL
end
```

:fire: l'instruction *config.vm.disk* est une fonctionnalité expérimentale de Vagrant, il est nécessaire de lancer la création de cette VM avec la variable d'environnement *VAGRANT_EXPERIMENTAL*

```
$ VAGRANT_EXPERIMENTAL="disks" vagrant up
```

Une fois que la VM estprovisionnée et que k3s est installé sur celle-ci, utilisez le fichier *kubeconfig.k3s* pour configurer votre client *kubectl*:

```
$ export KUBECONFIG=$PWD/kubeconfig.k3s
```

Vérifiez ensuite que vous pouvez lister les nodes de votre cluster (un seul dans cet exercice):

```
$ kubectl get nodes
NAME      STATUS   ROLES                  AGE   VERSION
vagrant   Ready    control-plane,master   2m    v1.20.4+k3s1
```

Vérifiez en même temps qu'un disque de 10G a bien été attaché à la VM, ce disque devrait apparaitre en tant que device */dev/sdb* comme illustré avec la commande suivante:

```
$ vagrant ssh -- sudo fdisk -l | grep 'Disk /dev/sd*'
Disk /dev/sda: 64 GiB, 68719476736 bytes, 134217728 sectors
Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
```

## Déploiement de rook

Premièrement, il est nécessaire de récupérer la branche correspondant au dernier tag du projet Rook sur [GitHub](https://github.com/rook/rook.git) et de se positionner dans le répertoire *rook/cluster/examples/kubernetes/ceph*:
 
Note: la dernière version est actuellement *v1.5.8* (mars 2021)

```
git clone --depth 1 --branch v1.5.8 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
```

Utilisez ensuite les commandes suivantes pour déployer l'opérateur dédié à la mise en place d'un cluster Ceph ainsi que les ressources dont il dépend:

```
kubectl apply -f crds.yaml -f common.yaml
kubectl apply -f operator.yaml
```

:information_source: l'opérateur est un processus qui tourne dans un Pod, il sera en charge de configurer un cluster de stockage Ceph en fonction de la spécification qui lui sera fournie dans la suite.

Vérifiez que l'opérateur est dans le statut *Running*, cela ne devrait prendre que quelques dizaines de secondes:

```
$ kubectl get pod -n rook-ceph
NAME                                  READY   STATUS    RESTARTS   AGE
rook-ceph-operator-6b8b9958c5-kddqd   1/1     Running   0          99s
```

## Création d'un cluster Ceph

Vous allez à présent créer une ressource de type *CephCluster*. L'opérateur que vous avez déployé précédemment détectera automatiquement cette ressource et déploiera un cluster Ceph en prenant en compte la spécification de celle-ci.

Créez la ressource *CephCluster* en utilisant la spécification disponible dans le fichier *cluster-test.yaml*:

```
$ kubectl apply -f cluster-test.yaml
```

:information_source: la ressource spécifiée dans *cluster-test.yaml* permet de mettre en place un cluster Ceph dans un contexte de test. Pour un contexte de production, il serait nécessaire d'utiliser le fichier *cluster.yaml* ainsi qu'un cluster Kubernetes comportant plusieurs nodes sur lesquels les processus de Ceph seraient installés, cela afin d'avoir un fonctionnement en haute disponibilité (HA).

Après quelques minutes les Pods en charge du stockage Ceph seront déployés. Vérifiez le à l'aide de la commande suivante: (tous les éléments relatifs à Ceph sont créés dans le namespace *rook-ceph*)

```
$ kubectl get pod -n rook-ceph
```

Vous obtiendrez un résultat similaire à celui ci dessous:

```
NAME                                            READY   STATUS      RESTARTS   AGE
rook-ceph-operator-6b8b9958c5-4xqbh             1/1     Running     0          6m4s
rook-ceph-mon-a-b67cb8984-zv7w4                 1/1     Running     0          5m13s
rook-ceph-mgr-a-ddf94f597-jqxlf                 1/1     Running     0          5m4s
rook-ceph-osd-prepare-vagrant-bp2vr             0/1     Completed   0          5m3s
rook-ceph-osd-0-5b6cc89b4b-5k5lv                1/1     Running     0          4m40s
csi-cephfsplugin-ssv5s                          3/3     Running     0          18s
csi-rbdplugin-sv4n6                             3/3     Running     0          19s
csi-cephfsplugin-provisioner-8658f67749-7l7kb   6/6     Running     0          18s
csi-rbdplugin-provisioner-6bc6766db-nncpx       6/6     Running     0          19s
```

:fire: lors de l'installation, Rook a pu détecter un disque non formaté attaché à l'unique node de votre cluster. Il a automatiquement utilisé ce disque comme support de stockage du cluster Ceph mis en place. Vous pourriez confirmer cela en regardant dans les logs du Pod *rook-ceph-osd-prepare-vagrant-...*.

En quelques lignes de commande, vous avez donc utilisé Rook pour mettre en place un cluster Ceph dans K3s !

Ceph est une solution très utilisée, elle met à disposition différents types de stockage:
- système de fichiers partagé
- stockage object
- stockage block

Dans la suite vous utiliserez le stockage block pour persister les données d'une application simple.

## Création d'une StorageClass

Pour pouvoir provisionner du stockage block de manière automatique, il faut tout d'abord créer une StorageClass. Pour cela, vous allez utiliser le fichier *cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml-test*:

```
$ kubectl apply -f ./csi/rbd/storageclass-test.yaml
```

:information_source: comme son nom l'indique, le fichier *storageclass-test.yaml* est adapté pour un environnement de test. Il ne doit pas être utilisé dans un environnement de production car cette configuration ne permet pas la réplication des données. Une autre spécification *storageclass.yaml* est dédiée à la mise en place d'une StorageClass pour la production, c'est-à dire permettant la réplication des données entre les différents nodes.

Il y a à présent 2 StorageClass qui sont définies dans votre cluster:
- local-path: celle-ci a été créée lors de l'installation de k3s, elle est utilisée par défaut si aucune StorageClass n'est spécifiée dans la spécification d'un PersistentVolumeClaim
- rook-ceph-block: celle-ci vient tout juste d'être créée

```
$ kubectl get sc
NAME                   PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path        Delete          WaitForFirstConsumer   false                  21m
rook-ceph-block        rook-ceph.rbd.csi.ceph.com   Delete          Immediate              true                   2m10s
```

En utilisant les commandes suivantes, vous allez définir *rook-ceph-block* comme StorageClass par défaut au lieu de *local-path*. Il s'agit seulement de modifier une annotation dans chacune de ces StorageClass:

```
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Vérifiez que les changements ont bien été effectués:

```
$ kubectl get sc
NAME                        PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path                  rancher.io/local-path        Delete          WaitForFirstConsumer   false                  24m
rook-ceph-block (default)   rook-ceph.rbd.csi.ceph.com   Delete          Immediate              true                   5m35s
```

## Lancement d'une application de test

Vous allez à présent déployer une application simple basée sur Ghost, une plateforme de blogging open source. Cette application est composée des 3 ressources suivantes:

- un Deployment basé sur l'image [Ghost](https://hub.docker.com/_/ghost)
- un Service de type NodePort qui expose l'application sur le port 31005
- un PersistentVolumeClaim qui utilise la StorageClass par défaut pour demander 1G de stockage

La spécification de cette application est définie ci-dessous. Vous pouvez voir que le PersistentVolumeClaim *ghost-pv-claim* est utilisé dans le Deployment *ghost*: le PersistentVolume qui sera associé à ce PersistentVolumeClaim sera monté dans le répertoire */var/lib/ghost/content* du container *ghost*, répertoire dans lequel Ghost persiste ses données.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ghost
spec:
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
        image: ghost
        ports:
        - containerPort: 2368
        volumeMounts:
        - name: ghost-data
          mountPath: /var/lib/ghost/content
      volumes:
      - name: ghost-data
        persistentVolumeClaim:
          claimName: ghost-pv-claim
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ghost-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
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
    nodePort: 31005
```

Installez cette application avec la commande suivante: 

```
$ kubectl apply -f https://luc.run/ghost-with-pvc.yaml
```

En quelques secondes, vous pourrez voir qu'un PersistentVolume a été créé et associé au PersistentVolumeClaim créé précédemment:

```
$ kubectl get pv,pvc
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS      REASON   AGE
persistentvolume/pvc-5e9aa1f8-534f-4103-8777-5571bf6cf2af   1Gi        RWO            Delete           Bound    default/ghost-pv-claim   rook-ceph-block            5s

NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
persistentvolumeclaim/ghost-pv-claim   Bound    pvc-5e9aa1f8-534f-4103-8777-5571bf6cf2af   1Gi        RWO            rook-ceph-block   7s
```

L'application est alors disponible sur le port 31005:

![Ghost interface](./images/ghost.png)

Toutes les données du Pod ghost sont stockées dans le disque supplémentaire attaché au node de votre cluster.

## Ceph dashboard & Rook Toolbox

L'installation de Ceph met également en place une interface web de gestion. Il est possible d'y accéder avec un port forward sur le service *rook-ceph-mgr-dashboard*

```
$ kubectl port-forward svc/rook-ceph-mgr-dashboard 7000:7000 -n rook-ceph
```

![Ceph dashboard](./images/ceph-dashboard-1.png)

L'utilisateur est *admin*, le mot de passe peut être récupéré avec la commande suivante:

```
$ kubectl -n rook-ceph get secret rook-ceph-dashboard-password \
  -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

Celui-ci permet d'avoir une vision très détaillée du cluster de stockage. N'hésitez pas à naviguer dans cette interface. 

![Ceph dashboard](./images/ceph-dashboard-2.png)


Rook met également à disposition une toolbox qui permet d'interagir avec le cluster Ceph en ligne de commande. Installez cette toolbox en utilisant la commande suivante:

```
$ kubectl apply -f https://luc.run/rook/toolbox.yaml
```

Une fois le Pod correctement créé, lancez un shell dans celui-ci:

```
$ kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```

De nombreuses commandes sont disponibles pour explorer l'intérieur du cluster Ceph, par exemple:

- ceph status
- ceph osd status
- ceph df

## En résumé

Rook a permis de mettre en place un cluster Ceph dans notre cluster Kubernetes. Nous avons pu utiliser du stockage block afin de persister des données d'une application Ghost.

Dans cet exercice, nous avons utilisé un seul node afin d'illustrer la mise en place de Rook. Cependant, dans un contexte de production, il serait nécessaire d'utiliser plusieurs nodes afin d'assurer la réplication des données entre ceux-ci. 

Rook permet d'orchestrer différentes solutions de stockage, notamment:
- Ceph (stable)
- Cassandra (alpha)
- NFS (alpha)

C'est un projet *Graduated* de la [CNCF](https://cncf.io), n'hésitez pas à le tester avec l'une des autres solutions de stockage proposées.
