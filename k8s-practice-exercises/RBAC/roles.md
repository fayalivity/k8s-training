Dans cet exercice vous allez créer des ressources *Role* / *RoleBinding* / *ClusterRole* / *ClusterRoleBinding* afin de donner certains droits à un utilisateur du cluster.

## Etat des lieux

Nous considérons qu'un utilisateur dont l'identifiant est *thomas* a le certificat nécessaire pour s'authentifier dans le cluster. Pour le moment aucun droit supplémentaire n'a été donné à cet utilisateur, vous pouvez le vérifier avec la commande suivante qui permet de se faire passer pour *thomas* et de lister les actions autorisées:

```
kubectl auth can-i --list --as thomas
```

Vous devriez obtenir un résultat similaire à celui ci-dessous:

```
Resources                                       Non-Resource URLs   Resource Names   Verbs
selfsubjectaccessreviews.authorization.k8s.io   []                  []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []               [create]
                                                [/api/*]            []               [get]
                                                [/api]              []               [get]
                                                [/apis/*]           []               [get]
                                                [/apis]             []               [get]
                                                [/healthz]          []               [get]
                                                [/healthz]          []               [get]
                                                [/livez]            []               [get]
                                                [/livez]            []               [get]
                                                [/openapi/*]        []               [get]
                                                [/openapi]          []               [get]
                                                [/readyz]           []               [get]
                                                [/readyz]           []               [get]
                                                [/version/]         []               [get]
                                                [/version/]         []               [get]
                                                [/version]          []               [get]
                                                [/version]          []               [get]
```

Ce résultat indique que l'utilisateur est autorisé à accéder à l'état de santé du cluster et quelques informations non sensibles.

## Droit de lister les nodes

Vous allez à présent permettre à *thomas* de lister les nodes du cluster.

- vérifier que l'utilisateur *thomas* n'a pas accès à cette action

En utilisant la commande suivante, confirmez que *thomas* ne peut pas faire cette action:

```
kubectl auth can-i list nodes --as thomas
```

Vous devriez obtenir le message suivant:

```
Warning: resource 'nodes' is not namespace scoped
no
```

- Création du ClusterRole

Copiez la spécification suivante dans le fichier *list-nodes.yaml*, celle-ci définit une ressource *ClusterRole* permettant de lister les nodes du cluster:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: list-nodes
rules:
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
```

Créez ensuite cette ressource:

```
kubectl apply -f list-nodes.yaml
```

Note: vous pouvez également créer ce *ClusterRole* avec la commande impérative suivante:

```
kubectl create clusterrole list-nodes --verb list --resource nodes 
```

- Association du ClusterRole à l'utilisateur *thomas*

Le *ClusterRole* créé précedemment ne sert à rien s'il n'est pas associé à un utilisateur. Copiez la spécification suivante dans le fichier *thomas-list-nodes.yaml*, celle-ci définit un *ClusterRoleBinding* permettant d'associer le *ClusterRole* à l'utilisateur.

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: thomas-list-nodes
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: list-nodes
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: thomas
```

Créez ensuite cette ressource:

```
kubectl apply -f thomas-list-nodes.yaml
```

Note: vous pouvez également créer ce *ClusterRoleBinding* avec la commande impérative suivante:

```
kubectl create clusterrolebinding thomas-list-nodes --clusterrole list-nodes --user thomas
```

- Vérification

Comme précédemment, la commande suivante permet de vérifier si l'utilisateur *thomas* peut lister les nodes:

```
kubectl auth can-i list nodes --as thomas
```

Vous devriez obtenir le message suivant:

```
Warning: resource 'nodes' is not namespace scoped
yes
```

## Droit de gérer des Deployment dans le namespace *dev*

Vous allez à présent permettre à *thomas* de manipuler (créer, lister, mettre à jour, supprimer) des Deployments dans le namespace *dev*.

- Création du namespace

Utilisez la commande suivante pour créer le namespace *dev*

```
kubectl create namespace dev
```

- vérifier que l'utilisateur *thomas* ne peux pas créer, lister ou supprimer de Deployment dans ce namespace:

```
kubectl auth can-i create deployments.apps --as thomas --namespace dev
kubectl auth can-i get deployments.apps --as thomas --namespace dev
kubectl auth can-i list deployments.apps --as thomas --namespace dev
kubectl auth can-i update deployments.app --as thomas --namespace dev
kubectl auth can-i delete deployments.app --as thomas --namespace dev
```

Chacune des commandes ci-dessus devrait vous retourner le résultat:

```
no
```

- Création du Role

Copiez la spécification suivante dans le fichier *manage-deployment.yaml*, celle-ci définit une ressource *Role* permettant de gérer les Deployments au sein du namespace *dev*:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: manage-deployment
  namespace: dev
rules:
- apiGroups:
  - "apps"
  resources:
  - deployments
  verbs:
  - create
  - list
  - get
  - update
  - delete
```

Créez ensuite cette ressource:

```
kubectl apply -f manage-deployment.yaml
```

Note: vous pouvez également créer ce *Role* avec la commande impérative suivante:

```
kubectl create role manage-deployment --verb create,list,get,update,delete --resource deployments.apps --namespace dev 
```

- Association du Role à l'utilisateur *thomas*

Copiez la spécification suivante dans le fichier *thomas-manage-deployment.yaml*, celle-ci définit un *RoleBinding* permettant d'associer le *Role* précédent à *thomas*:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: thomas-manage-deployment
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: manage-deployment
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: thomas
```

Créez ensuite cette ressource:

```
kubectl apply -f thomas-manage-deployment.yaml
```

Note: vous pouvez également créer ce *RoleBinding* avec la commande impérative suivante:

```
kubectl create rolebinding thomas-manage-deployment --role manage-deployment --user thomas --namespace dev
```

- Vérification

Comme précédemment, la commande ci-dessous permet de vérifier si l'utilisateur *thomas* peut faire les différentes actions sur la ressource de type Deployment:

```
kubectl auth can-i create deployments.apps --as thomas --namespace dev
kubectl auth can-i get deployments.apps --as thomas --namespace dev
kubectl auth can-i list deployments.apps --as thomas --namespace dev
kubectl auth can-i update deployments.app --as thomas --namespace dev
kubectl auth can-i delete deployments.app --as thomas --namespace dev
```

Cette fois-ci vous devriez obtenir le message suivant pour chacune de ces commandes:

```
yes
```

## Droits associés à l'utilisateur

Comme vous l'aviez fait au début de l'exercice, vérifier les différentes actions qui sont autorisées pour l'utilisateur *thomas* dans le namespace *dev*:

```
kubectl auth can-i --list --as thomas -n dev
```

Vous devriez obtenir le résultat suivant:

```
Resources                                       Non-Resource URLs   Resource Names   Verbs
deployments.apps                                []                  []               [create list get update delete]
selfsubjectaccessreviews.authorization.k8s.io   []                  []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []               [create]
                                                [/api/*]            []               [get]
                                                [/api]              []               [get]
                                                [/apis/*]           []               [get]
                                                [/apis]             []               [get]
                                                [/healthz]          []               [get]
                                                [/healthz]          []               [get]
                                                [/livez]            []               [get]
                                                [/livez]            []               [get]
                                                [/openapi/*]        []               [get]
                                                [/openapi]          []               [get]
                                                [/readyz]           []               [get]
                                                [/readyz]           []               [get]
                                                [/version/]         []               [get]
                                                [/version/]         []               [get]
                                                [/version]          []               [get]
                                                [/version]          []               [get]
nodes                                           []                  []               [list]
```

Vous retrouvez dans ce résultat les droits de gestion des Deployments dans le namespace *dev* ainsi que le droit de lister les nodes dans le cluster.