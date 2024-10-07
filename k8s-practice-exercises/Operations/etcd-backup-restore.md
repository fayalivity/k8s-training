Dans cet exercice vous allez créer un backup de *etcd*, la base de données clé / valeur contenant l'état d'un cluster Kubernetes. 

## Pré-requis

Pour cet exercice, il est nécessaire d'avoir un cluster créé avec *kubeadm* comme détaillé dans cet exercice:
[https://gitlab.com/lucj/k8s-exercices/-/blob/master/Installation/kubeadm.md](https://gitlab.com/lucj/k8s-exercices/-/blob/master/Installation/kubeadm.md)

## Communication avec etcd

Lancez un shell sur le node master:

```
multipass shell master
```

Note: toutes les commandes qui suivent devront être lancées depuis ce shell.

Dans le répertoire */etc/kubernetes/pki/etcd*, vous trouverez les certificats utilisé par l'API Server pour se connecter à etcd.

Vous allez utiliser le binaire *etcdctl* (installé sur le node master lors de la mise en place du cluster) pour communiquer avec etcd. Par exemple, vous pouvez connaitre l'état de l'instance etcd en utilisant la commande suivante:

```
sudo ETCDCTL_API=3 etcdctl \
--endpoints localhost:2379 \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
endpoint health
```

Vous devriez obtenir un résultat proche du suivant:

```
localhost:2379 is healthy: successfully committed proposal: took = 14.891442ms
```

Note: ce cluster de test ne comporte qu'une seule instance. Dans un cluster de production, il est nécessaire d'avoir au minimum un cluster etcd de 3 instances, celles-ci pouvant être sur les nodes master ou bien à l'extérieur du cluster Kubernetes.

## Création d'un backup

Avant d'effectuer un backup d'etcd, créez un déployment de test:

```
kubectl create deploy nginx --image=nginx:1.20 --replicas=4
```

puis vérifiez que les 4 Pods du Deployment tournent correctement.

Lancez ensuite la commande suivante afin de faire un backup de etcd: 

```
sudo ETCDCTL_API=3 etcdctl snapshot save \
--endpoints localhost:2379 \
--cacert /etc/kubernetes/pki/etcd/server.crt \
--cert /etc/kubernetes/pki/etcd/ca.crt \
--key /etc/kubernetes/pki/etcd/ca.key \
snapshot.db
```

Vous obtiendrez un résultat similaire au suivant:

```
{"level":"info","ts":1647208530.7104492,"caller":"snapshot/v3_snapshot.go:68","msg":"created temporary db file","path":"snapshot.db.part"}
{"level":"info","ts":1647208530.7236032,"logger":"client","caller":"v3/maintenance.go:211","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":1647208530.7239015,"caller":"snapshot/v3_snapshot.go:76","msg":"fetching snapshot","endpoint":"localhost:2379"}
{"level":"info","ts":1647208530.775834,"logger":"client","caller":"v3/maintenance.go:219","msg":"completed snapshot read; closing"}
{"level":"info","ts":1647208530.7927103,"caller":"snapshot/v3_snapshot.go:91","msg":"fetched snapshot","endpoint":"localhost:2379","size":"2.7 MB","took":"now"}
{"level":"info","ts":1647208530.7928133,"caller":"snapshot/v3_snapshot.go:100","msg":"saved","path":"snapshot.db"}
Snapshot saved at snapshot.db
```

Le backup est sauvegardé dans le fichier *snapshot.db* sur le master.

:warning: pour un cluster de production le backup ne devra pas rester sur un node master mais être déplacé sur un stockage extérieur au cluster, par exemple un stockage object.

A l'aide de la commande suivante, vérifier que le backup a été effectué correctement:

```
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status snapshot.db
```

Vous obtiendrez un résultat proche du suivant:

```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 37f3f370 |     1592 |        993 |     2.7 MB |
+----------+----------+------------+------------+
```

## Restauration du backup

Avant de restaurer le backup précédent, lancer un nouveau Deployment dans le cluster:

```
kubectl create deploy mongo --image=mongo:5.0
```

Puis vérifier que vous avez à présent 2 Deployments et que les Pods associés sont dans l'état *Running*:

```
kubectl get deploy,po
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mongo   1/1     1            1           20s
deployment.apps/nginx   4/4     4            4           6m26s

NAME                         READY   STATUS    RESTARTS   AGE
pod/mongo-857d4c74ff-tkl9g   1/1     Running   0          20s
pod/nginx-6d777db949-24bm6   1/1     Running   0          6m26s
pod/nginx-6d777db949-9xwfs   1/1     Running   0          6m26s
pod/nginx-6d777db949-drdhb   1/1     Running   0          6m26s
pod/nginx-6d777db949-zlc8t   1/1     Running   0          6m26s
```

Restaurez ensuite le backup dans le répertoire */var/lib/etcd-snapshot* (celui-ci sera créé automatiquement):

```
sudo ETCDCTL_API=3 etcdctl snapshot restore \
--endpoints localhost:2379 \
--cacert /etc/kubernetes/pki/etcd/server.crt \
--cert /etc/kubernetes/pki/etcd/ca.crt \
--key /etc/kubernetes/pki/etcd/ca.key \
--data-dir /var/lib/etcd-snapshot \
snapshot.db
```

Vous devriez obtenir un message proche de celui ci-dessous:

```
2022-03-14T16:40:06Z	info	snapshot/v3_snapshot.go:251	restoring snapshot	{"path": "snapshot.db", "wal-dir": "/var/lib/etcd-snapshot/member/wal", "data-dir": "/var/lib/etcd-snapshot", "snap-dir": "/var/lib/etcd-snapshot/member/snap", "stack": "go.etcd.io/etcd/etcdutl/v3/snapshot.(*v3Manager).Restore\n\t/tmp/etcd-release-3.5.2/etcd/release/etcd/etcdutl/snapshot/v3_snapshot.go:257\ngo.etcd.io/etcd/etcdutl/v3/etcdutl.SnapshotRestoreCommandFunc\n\t/tmp/etcd-release-3.5.2/etcd/release/etcd/etcdutl/etcdutl/snapshot_command.go:147\ngo.etcd.io/etcd/etcdctl/v3/ctlv3/command.snapshotRestoreCommandFunc\n\t/tmp/etcd-release-3.5.2/etcd/release/etcd/etcdctl/ctlv3/command/snapshot_command.go:128\ngithub.com/spf13/cobra.(*Command).execute\n\t/usr/local/google/home/siarkowicz/.gvm/pkgsets/go1.16.3/global/pkg/mod/github.com/spf13/cobra@v1.1.3/command.go:856\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\t/usr/local/google/home/siarkowicz/.gvm/pkgsets/go1.16.3/global/pkg/mod/github.com/spf13/cobra@v1.1.3/command.go:960\ngithub.com/spf13/cobra.(*Command).Execute\n\t/usr/local/google/home/siarkowicz/.gvm/pkgsets/go1.16.3/global/pkg/mod/github.com/spf13/cobra@v1.1.3/command.go:897\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.Start\n\t/tmp/etcd-release-3.5.2/etcd/release/etcd/etcdctl/ctlv3/ctl.go:107\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.MustStart\n\t/tmp/etcd-release-3.5.2/etcd/release/etcd/etcdctl/ctlv3/ctl.go:111\nmain.main\n\t/tmp/etcd-release-3.5.2/etcd/release/etcd/etcdctl/main.go:59\nruntime.main\n\t/usr/local/google/home/siarkowicz/.gvm/gos/go1.16.3/src/runtime/proc.go:225"}
2022-03-14T16:40:06Z	info	membership/store.go:141	Trimming membership information from the backend...
2022-03-14T16:40:06Z	info	membership/cluster.go:421	added member	{"cluster-id": "cdf818194e3a8c32", "local-member-id": "0", "added-peer-id": "8e9e05c52164694d", "added-peer-peer-urls": ["http://localhost:2380"]}
2022-03-14T16:40:06Z	info	snapshot/v3_snapshot.go:272	restored snapshot	{"path": "snapshot.db", "wal-dir": "/var/lib/etcd-snapshot/member/wal", "data-dir": "/var/lib/etcd-snapshot", "snap-dir": "/var/lib/etcd-snapshot/member/snap"}
```

Il est ensuite nécessaire de modifier la configuration du Pod etcd de façon à ce qu'il prenne en compte le contenu du nouveau répertoire */var/lib/etcd-snapshot* au lieu de */var/lib/etcd*. Modifiez pour cela le path présent dans le volumes de type *hostPath* nommé *etcd-data* (à la fin de la spécification du Pod):

```
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://10.214.56.82:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://10.214.56.82:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://10.214.56.82:2380
    - --initial-cluster=master=https://10.214.56.82:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://10.214.56.82:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://10.214.56.82:2380
    - --name=master
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    image: k8s.gcr.io/etcd:3.5.1-0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: etcd
    resources:
      requests:
        cpu: 100m
        memory: 100Mi
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd-snapshot   <== Nouveau chemin d'accès aux data
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```

Au bout de quelques secondes le Pod *etcd* sera automatiquement redémarré par *kubelet* avec le contenu du snapshot précédent.

Vérifiez alors que seul le Deployment *nginx* est présent dans le cluster:

```
kubectl get deploy
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   4/4     4            4           20m
```

Le Deployment mongo n'est pas listé car il a été créé après avoir fait le backup de etcd.