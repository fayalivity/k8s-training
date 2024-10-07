K3d est un outils qui permet de déployer un cluster k3s de façon à ce que chacun des nodes du cluster tourne dans un container Docker. Pour utiliser K3d, il faudra simplement récupérer le binaire associé et le lancer dans un environnement sur lequel Docker est installé.

### 1. Installation de K3d

Pour installer K3d, il suffit de lancer la commande suivante:

```
$ curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

Vérifiez ensuite la version de k3d ainsi que la version du cluster k3s qui sera installé:

```
$ k3d version
k3d version v4.2.0
k3s version v1.20.2-k3s1 (default)
```

### 2. Création d'un cluster

La commande suivante créé un cluster, nommé *k3s*, contenant 2 nodes worker (agent k3s) en plus du node master (server k3s)

```
$ k3d cluster create k3s --agents 2
INFO[0000] Prep: Network
INFO[0000] Created network 'k3d-k3s'
INFO[0000] Created volume 'k3d-k3s-images'
INFO[0001] Creating node 'k3d-k3s-server-0'
INFO[0003] Pulling image 'docker.io/rancher/k3s:v1.20.2-k3s1'
INFO[0010] Creating node 'k3d-k3s-agent-0'
INFO[0010] Creating node 'k3d-k3s-agent-1'
INFO[0010] Creating LoadBalancer 'k3d-k3s-serverlb'
INFO[0012] Pulling image 'docker.io/rancher/k3d-proxy:v4.2.0'
INFO[0015] Starting cluster 'k3s'
INFO[0015] Starting servers...
INFO[0015] Starting Node 'k3d-k3s-server-0'
INFO[0022] Starting agents...
INFO[0022] Starting Node 'k3d-k3s-agent-0'
INFO[0035] Starting Node 'k3d-k3s-agent-1'
INFO[0043] Starting helpers...
INFO[0043] Starting Node 'k3d-k3s-serverlb'
INFO[0045] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access
INFO[0051] Successfully added host record to /etc/hosts in 4/4 nodes and to the CoreDNS ConfigMap
INFO[0051] Cluster 'k3s' created successfully!
INFO[0051] --kubeconfig-update-default=false --> sets --kubeconfig-switch-context=false
INFO[0051] You can now use it like this:
kubectl config use-context k3d-k3s
kubectl cluster-info
```

De nombreuses options sont disponibles lors de la création d'un cluster. Celles-ci peuvent être visualisée avec la commande suivante:

```
$ k3d cluster create --help
```

Une fois le cluster créé, nous pouvons lister les différents containers qui ont été lancés:

```
$ docker ps
CONTAINER ID   IMAGE                      COMMAND                  CREATED         STATUS         PORTS                             NAMES
74dbefe8f431   rancher/k3d-proxy:v4.2.0   "/bin/sh -c nginx-pr…"   3 minutes ago   Up 2 minutes   80/tcp, 0.0.0.0:56150->6443/tcp   k3d-k3s-serverlb
1042c00f61aa   rancher/k3s:v1.20.2-k3s1   "/bin/k3s agent"         3 minutes ago   Up 2 minutes                                     k3d-k3s-agent-1
dac6ab81c7f7   rancher/k3s:v1.20.2-k3s1   "/bin/k3s agent"         3 minutes ago   Up 2 minutes                                     k3d-k3s-agent-0
9fa407bacddd   rancher/k3s:v1.20.2-k3s1   "/bin/k3s server --t…"   3 minutes ago   Up 2 minutes                                     k3d-k3s-server-0
```

Note: un container basé sur l'image *k3d-proxy* a été créé en plus des containers nécessaires pour k3s. Celui-ci est utilisé en tant que loadbalancer pour accéder au cluster.

La commande suivante permet de lister les clusters créés avec k3d (un seul dans cet exemple):

```
$ k3d cluster list
NAME   SERVERS   AGENTS   LOADBALANCER
k3s    1/1       2/2      true
```

### 3. kubeconfig

Comme spécifié dans le résultat ci-dessus, la commande suivante permet de configurer *kubectl* pour qu'il communique avec le cluster:

```
$ kubectl config use-context k3d-k3s
Switched to context "k3d-k3s"
```

Nous pouvons alors lister les nodes du cluster:

```
$ kubectl get nodes
NAME               STATUS   ROLES                  AGE   VERSION
k3d-k3s-agent-0    Ready    <none>                 13m   v1.20.2+k3s1
k3d-k3s-agent-1    Ready    <none>                 13m   v1.20.2+k3s1
k3d-k3s-server-0   Ready    control-plane,master   13m   v1.20.2+k3s1
```

Le cluster est près à être utilisé.

### 4. Delete cluster

La commande suivante permet de supprimer le cluster que nous avons mis en place:

```
$ k3d cluster delete k3s
INFO[0000] Deleting cluster 'k3s'
INFO[0000] Deleted k3d-k3s-serverlb
INFO[0000] Deleted k3d-k3s-agent-1
INFO[0001] Deleted k3d-k3s-agent-0
INFO[0003] Deleted k3d-k3s-server-0
INFO[0003] Deleting cluster network 'k3d-k3s'
INFO[0003] Deleting image volume 'k3d-k3s-images'
INFO[0003] Removing cluster details from default kubeconfig...
INFO[0003] Removing standalone kubeconfig file (if there is one)...
INFO[0003] Successfully deleted cluster k3s!
```