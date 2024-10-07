[Kyverno](https://github.com/kyverno/kyverno) est une solution de sécurité pour Kubernetes, celle-ci peut valider, modifier et générer des spécifications en utilisant des admissions controlleurs. L'un des avantage de Kyverno sur des solutions concurrentes réside dans le fait que la définition des règles se base sur des ressources Kubernetes (CRD).

## Installation

Suivez la procédure suivante pour installer Kyverno en utilisant Helm:

- Ajout du répository

```
helm repo add kyverno https://kyverno.github.io/kyverno/
```

- Mise à jour pour récupérer la liste des charts disponibles

```
helm repo update
```

- Installation de *kyverno* dans le namespace du même nom

```
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

Vérifiez que le Pod Kyverno tourne correctement:

```
$ kubectl get po -n kyverno
NAME                       READY   STATUS    RESTARTS   AGE
kyverno-6ffff9dc94-rlwj4   1/1     Running   0          2m15s
```

Vous pouvez également observer que l'installation de Kyverno a créé des resources de type *MutatingWebhookConfiguration* et *ValidatingWebhookConfiguration*:

```
$ kubectl get mutatingwebhookconfigurations
NAME                                    WEBHOOKS   AGE
kyverno-policy-mutating-webhook-cfg     1          2m53s
kyverno-resource-mutating-webhook-cfg   2          2m52s
kyverno-verify-mutating-webhook-cfg     1          2m53s

$ kubectl get validatingwebhookconfigurations
NAME                                      WEBHOOKS   AGE
kyverno-policy-validating-webhook-cfg     1          66s
kyverno-resource-validating-webhook-cfg   2          66s
```

## Utilisation

Dans la suite vous allez créer plusieurs règles (on parle de *Policy* dans Kyverno) qui permettront d'ajouter des contraintes au niveau du cluster ou bien limité à un namespace.

- Définition d'une Policy au niveau du cluster

La spécification suivante définit une ClusterPolicy au niveau du cluster, celle-ci s'assure qu'aucun Pod ne soit créé si il n'a pas de label nommé *app.kubernetes.io/name*.

```
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce
  rules:
  - name: check-for-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "label 'app.kubernetes.io/name' is required"
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
```

Copiez cette spécification dans le fichier *cluster-pod-label-policy.yaml* et créez la ressource:

```
kubectl apply -f cluster-pod-label-policy.yaml
```

Vérifiez cette ClusterPolicy en créant le Deployment suivant qui ne contient pas le label 

```
kubectl create deployment nginx --image=nginx
```

Vous obtiendrez un message d'erreur similaire au suivant:

```
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/nginx was blocked due to the following policies

require-labels:
  autogen-check-for-labels: 'validation error: label ''app.kubernetes.io/name'' is
    required. Rule autogen-check-for-labels failed at path /spec/template/metadata/labels/app.kubernetes.io/name/'
```

Supprimez cette ClusterPolicy:

```
kubectl delete -f cluster-pod-label-policy.yaml
```

- Définition d'une Policy limitée à un namespace

La spécification suivante définit une Policy qui ajoute automatiquement la propriété label *app.kubernetes.io/name* aux Pods qui n'en ont pas:

```
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: require-labels
spec:
  validationFailureAction: enforce
  rules:
  - name: check-for-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            +(app.kubernetes.io/name): "{{request.object.metadata.name}}"
```

Copiez cette spécification dans le fichier *pod-add-label-policy.yaml* et créez la ressource dans un nouveau namespace *test*:

```
kubectl create ns test
kubectl apply -f pod-add-label-policy.yaml -n test
```

Créez le Pod suivant: 

```
kubectl run mongo --image=mongo:5.0
```

et vérifiez que le label *app.kubernetes.io/name: mongo* a bien été ajouté:

```
$ kubectl get po mongo -o jsonpath='{.metadata.labels}'
{"app.kubernetes.io/name":"mongo","run":"mongo"}
```

Supprimez la Policy:

```
kubectl delete -f pod-add-label-policy.yaml -n test
```

- Génération automatique d'une ressource

La spécification suivante définit une ClusterPolicy qui crée automatiquement une NetworkPolicy qui empêche tout trafic entre les Pods lorsqu'un nouveau namespace est créé:

```
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default
spec:
  rules:
  - name: deny-all-traffic
    match:
      any:
      - resources:
          kinds:
          - Namespace
    exclude:
      any:
      - resources:
          namespaces:
          - kube-system
          - default
          - kube-public
          - kyverno
    generate:
      kind: NetworkPolicy
      name: deny-all-traffic
      namespace: "{{request.object.metadata.name}}"
      data:  
        spec:
          # select all pods in the namespace
          podSelector: {}
          policyTypes:
          - Ingress
          - Egress
```

Copiez cette spécification dans le fichier *add-network-policy.yaml* et créez la ressource:

```
kubectl apply -f pod-add-label-policy.yaml
```

Créez un nouveau namespace et vérifiez qu'une NetworkPolicy a été créée dans celui-ci:

```
kubectl create ns test
kubectl -n test get netpol
```

Vous devriez obtenir un résultat similaire au suivant:

```
NAME               POD-SELECTOR   AGE
deny-all-traffic   <none>         4s
```

## Résumé

Kyverno est une solution qui se positionne comme une alternative aux *PodSecurityPolicy* qui sont dépréciées depuis Kubernetes 1.21 et qui seront supprimées à partir de la version 1.25. 

Un des points forts de Kyverno est d'utiliser des CRDs pour définir les règles à appliquer au niveau du cluster (*ClusterPolicy*) ou d'un namespace (*Policy*).

De nombreux exemples de *Policy* et de *ClusterPolicy* sont disponibles sur [https://kyverno.io/policies/](https://kyverno.io/policies/)