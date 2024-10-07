Dans cet exercice vous allez utiliser [Kubescape](https://github.com/armosec/kubescape) pour scanner votre cluster

## A propos de Kubescape

[Kubescape](https://github.com/armosec/kubescape) scan les cluster Kubernetes, les fichiers yaml ainsi que les charts Helm. Il permet de détecter des problèmes potentiels tels que:

- des problèmes de configuration
- des vulnérabilités
- des roles RBAC mal définis

Kubescape se base pour cela sur différents frameworks:

 - [nsa framework](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/2716980/nsa-cisa-release-kubernetes-hardening-guidance/)

- [MITRE ATT&CK®](https://www.microsoft.com/security/blog/2021/03/23/secure-containerized-environments-with-updated-threat-matrix-for-kubernetes/)

- DevOpsBest

- ArmoBest

## Installation

Kubescape est un binaire qui est disponible pour Linux / MacOS / Windows. Utilisez l'une des commandes suivante pour l'installer sur votre environnement:

- Linux:

```
curl -s https://raw.githubusercontent.com/armosec/kubescape/master/install.sh | /bin/bash
```

- MacOS

```
brew tap armosec/kubescape
brew install kubescape
```

- Windows

```
iwr -useb https://raw.githubusercontent.com/armosec/kubescape/master/install.ps1 | iex
```

## Lancement

Note: Kubescape communique avec le cluster associé au contexte courant

A l'aide de la commande suivante, lancez un scan en prenant en compte l'ensemble des controls disponibles dans les différents frameworks:

```
kubescape scan
```

Vous obtiendrez un rapport détaillé de l'état de votre cluster, Kubescan effectuant de nombreux contrôles sur celui-ci. A la fin, vous aurez un tableau récapitulatif des différentes contôles de la note de votre cluster.

Voici un exemple de ce tableau:

```
Summary - Passed:8   Excluded:0   Failed:2   Total:10
Remediation: Refrain from using the hostPath mount or use the exception mechanism to remove unnecessary notifications.

+-----------------------------------------------------------------------+------------------+--------------------+---------------+--------------+
|                             CONTROL NAME                              | FAILED RESOURCES | EXCLUDED RESOURCES | ALL RESOURCES | % RISK-SCORE |
+-----------------------------------------------------------------------+------------------+--------------------+---------------+--------------+
| Access Kubernetes dashboard                                           |        0         |         0          |      82       |      0%      |
| Access container service account                                      |        48        |         0          |      48       |     100%     |
| Access tiller endpoint                                                |        0         |         0          |       0       |   skipped    |
| Allow privilege escalation                                            |        7         |         0          |      11       |     61%      |
| Allowed hostPath                                                      |        2         |         0          |      10       |     16%      |
| Applications credentials in configuration files                       |        0         |         0          |      22       |      0%      |
| Audit logs enabled                                                    |        0         |         0          |       0       |   skipped    |
| Automatic mapping of service account                                  |        55        |         0          |      55       |     100%     |
| CVE-2021-25741 - Using symlink for arbitrary host file system access. |        0         |         0          |       0       |   skipped    |
| CVE-2021-25742-nginx-ingress-snippet-annotation-vulnerability         |        0         |         0          |       0       |   skipped    |
| CVE-2022-0185-linux-kernel-container-escape                           |        3         |         0          |       3       |     100%     |
| CVE-2022-0492-cgroups-container-escape                                |        6         |         0          |      10       |     67%      |
| CVE-2022-24348-argocddirtraversal                                     |        0         |         0          |       0       |   skipped    |
| Cluster internal networking                                           |        5         |         0          |       5       |     100%     |
| Cluster-admin binding                                                 |        1         |         0          |      72       |      1%      |
| Configured liveness probe                                             |        3         |         0          |      10       |     24%      |
| Configured readiness probe                                            |        4         |         0          |      10       |     41%      |
| Container hostPort                                                    |        0         |         0          |      10       |      0%      |
| Containers mounting Docker socket                                     |        0         |         0          |      10       |      0%      |
| Control plane hardening                                               |        0         |         0          |       0       |   skipped    |
| CoreDNS poisoning                                                     |        3         |         0          |      72       |      4%      |
| Data Destruction                                                      |        17        |         0          |      72       |     23%      |
| Delete Kubernetes events                                              |        3         |         0          |      72       |      4%      |
| Disable anonymous access to Kubelet service                           |        0         |         0          |       0       |   skipped    |
| Enforce Kubelet client TLS authentication                             |        0         |         0          |       0       |   skipped    |
| Exec into container                                                   |        1         |         0          |      72       |      1%      |
| Exposed dashboard                                                     |        0         |         0          |       0       |   skipped    |
| Exposed sensitive interfaces                                          |        0         |         0          |       0       |   skipped    |
| Forbidden Container Registries                                        |        0         |         0          |      10       |      0%      |
| Host PID/IPC privileges                                               |        0         |         0          |      10       |      0%      |
| HostNetwork access                                                    |        2         |         0          |      10       |     16%      |
| HostPath mount                                                        |        2         |         0          |      10       |     16%      |
| Image pull policy on latest tag                                       |        0         |         0          |      10       |      0%      |
| Images from allowed registry                                          |        4         |         0          |      10       |     41%      |
| Immutable container filesystem                                        |        8         |         0          |      10       |     74%      |
| Ingress and Egress blocked                                            |        10        |         0          |      10       |     100%     |
| Insecure capabilities                                                 |        0         |         0          |      10       |      0%      |
| K8s common labels usage                                               |        10        |         0          |      10       |     100%     |
| Kubernetes CronJob                                                    |        0         |         0          |       0       |   skipped    |
| Label usage for resources                                             |        10        |         0          |      10       |     100%     |
| Linux hardening                                                       |        8         |         0          |      10       |     74%      |
| List Kubernetes secrets                                               |        13        |         0          |      72       |     18%      |
| Malicious admission controller (mutating)                             |        0         |         0          |       0       |   skipped    |
| Malicious admission controller (validating)                           |        1         |         0          |       1       |     100%     |
| Mount service principal                                               |        2         |         0          |      10       |     16%      |
| Naked PODs                                                            |        1         |         0          |      18       |      5%      |
| Namespace without service accounts                                    |        3         |         0          |      50       |      6%      |
| Network mapping                                                       |        5         |         0          |       5       |     100%     |
| No impersonation                                                      |        1         |         0          |      72       |      1%      |
| Non-root containers                                                   |        8         |         0          |      10       |     83%      |
| PSP enabled                                                           |        0         |         0          |       0       |   skipped    |
| Pods in default namespace                                             |        1         |         0          |      10       |      8%      |
| Portforwarding privileges                                             |        1         |         0          |      72       |      1%      |
| Privileged container                                                  |        2         |         0          |      10       |     16%      |
| Resource policies                                                     |        8         |         0          |      10       |     64%      |
| Resources CPU limit and request                                       |        8         |         0          |      10       |     64%      |
| Resources memory limit and request                                    |        8         |         0          |      10       |     64%      |
| SSH server running inside container                                   |        0         |         0          |       0       |   skipped    |
| Secret/ETCD encryption enabled                                        |        0         |         0          |       0       |   skipped    |
| Sudo in container entrypoint                                          |        0         |         0          |      10       |      0%      |
| Writable hostPath mount                                               |        2         |         0          |      10       |     16%      |
+-----------------------------------------------------------------------+------------------+--------------------+---------------+--------------+
|                           RESOURCE SUMMARY                            |       117        |         0          |      168      |    23.31%    |
+-----------------------------------------------------------------------+------------------+--------------------+---------------+--------------+
FRAMEWORKS: DevOpsBest (risk: 34.81), MITRE (risk: 16.48), ArmoBest (risk: 21.48), NSA (risk: 28.53)
```

Sélectionnez quelques uns de ces contrôles et essayer de comprendre leur domaine d'application.

L'option *--enable-host-scan* permet de lancer des contrôles supplémentaires en lançant un scanner sur chaque node 

```
kubescape scan --enable-host-scan
```

kubescape offre différentes options lors du lancement d'un scan:

- la sélection d'un framework (*mitre*, *nsa*, *devopsbest*, *armobest*)

la commande suivante lance par exemple un scan en se basant exclusivement sur le framwork *nsa*:

```
kubescape scan framework nsa
```

- la sélection d'un control précis

Grace à la [liste des contrôles disponibles](https://hub.armo.cloud/docs/controls) il est possible de ne lancer qu'un contrôlé précis, par exemple:

```
kubescape scan control "SSH server running inside container"
```

Note: le nom ou l'identifiant du contrôle peuvent être utilisé. La commande ci-dessus est équivalente à celle qui suit:

```
kubescape scan control "C-0042"
```

- la restriction du scan à un ou plusieurs namespace:

```
kubescape scan --include-namespaces development,staging,production
```

- l'exclusion d'un ou plusieurs namespace lors du scan

```
kubescape scan --exclude-namespaces kube-system,kube-public
```

## Scan de manifests

kubescape permet également de scanner des fichiers yaml en local ou bien accessibles via une URL.

Créez par exemple la spécification d'un Deployment simple:

```
kubectl create deployment ghost --image=ghost:4 --replicas 2 --dry-run=client -o yaml > ghost.yaml
```

Lancez ensuite le scan sur le fichier généré:

```
kubescape scan ghost.yaml
```

A partir du résultat de ce scan, effectuez quelques corrections sur la spécification de façon à réduire son risk (colonne *RISK-SCORE*)


<details>
  <summary markdown="span">Indice</summary>

La spécification suivante permet de diminuer le risque, mais des actions supplémentaires sont nécessaires pour augmenter le niveau de sécurité.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ghost
  name: ghost
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ghost
  strategy: {}
  template:
    metadata:
      labels:
        app: ghost
    spec:
      containers:
      - image: ghost:4
        name: ghost
        securityContext:
          privileged: false
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
        resources:
          requests:
            cpu: 200m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 64Mi
```

</details>

## Scan de chart Helm

Afin de lancer un scan sur un chart Helm, il est nécessaire d'évaluer l'ensemble des templates du chart puis de passer les manifests yaml résultant à kubescape.

Les commandes suivantes permettent, par exemple, de scanner le chart Helm du Ingress Controller basé sur Traefik:

```
helm add repo traefik https://helm.traefik.io/traefik
helm template traefik traefik/traefik --dry-run | kubescape scan -
```

## Résumé

Kubescape est basé sur OpenPolicyAgent (https://github.com/open-policy-agent/opa), c'est un outil très puissant pour l'analyse d'un cluster. N'hésitez pas à le lancer et à décortiquer les rapports qu'il produit afin de sécuriser votre cluster.
