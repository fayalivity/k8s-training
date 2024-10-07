Dans cet exercice vous allez activer la génération des logs d'audit.

## Prérequis

Assurez-vous d'avoir accès à un cluster créé avec *kubeadm*.

Pour cet exercice nous utilisons un cluster dont les nodes sont les suivants:

```
$ kubectl get nodes
control-plane   Ready    control-plane   92s   v1.28.4
worker1         Ready    <none>          71s   v1.28.4
worker2         Ready    <none>          51s   v1.28.4
``````

## A propos des logs d'audit

Le niveau de logging des logs d'audit peut être défini à différents niveaux:

- None: les évènements associés ne sont pas loggués
- Metadata: les meta-données des évènements sont loggées (requestor, timestamp, resource, verb, etc.) mais les body des requêtes et réponses ne le sont pas
- Request: les meta-données et le body de la requète sont loggés, le body de la réponse n'est par contre pas loggué
- RequestResponse: les méta-données et les body des requêtes et réponses sont loggués

Dans le cadre de cet exercice nous allons considérer une Policy d'audit qui loggue les meta-données de chaque requète envoyée à l'API Server. Nous utiliserons pour cela le fichier de configuration suivant:

```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```

En utilisant la documentation suivante: [https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/) configurez l'API Server afin d'activer les logs d'audit. Assurez-vous de configurer un *log backend*. Créez ensuite un pod simple et vérifiez que la création de ce Pod est bien logguée dans le fichier contenant les logs d'audit.

<details>
  <summary markdown="span">Solution</summary>

1. Sur le node *controlplane*, créez le fichier */etc/kubernetes/audit-policy.yaml* dont le contenu est le suivant:

```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```

2. Modifiez la spécification du Pod de l'API Server (dans le fichier */etc/kubernetes/manifests/kube-apiserver.yaml*) en ajoutant la définition des 2 volumes suivants:

```
- name: audit
  hostPath:
    path: /etc/kubernetes/audit-policy.yaml
    type: File
- name: audit-log
  hostPath:
    path: /var/log/kubernetes/audit/
    type: DirectoryOrCreate
```

et en ajoutant également les instructions suivantes dans le champs *volumeMounts* du container:

```
- mountPath: /etc/kubernetes/audit-policy.yaml
    name: audit
    readOnly: true
- mountPath: /var/log/kubernetes/audit/
  name: audit-log
  readOnly: false
```

3. Lancez un Pod simple

```
kubectl run www --image=nginx:1.24
```

4. Vérifiez que des logs d'audit ont bien été générés dans le répertoire */var/log/kubernetes/audit/* de la machine *controlplane*

</details>