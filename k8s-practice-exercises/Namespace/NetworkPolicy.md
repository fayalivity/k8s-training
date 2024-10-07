Dans cet exercice, vous allez mettre en place des ressources de type NetworkPolicy de façon à isoler, au niveau network, les Pods qui tournent dans un namespace.

## Création d'un namespace

Créez le namespace *demo*:

```
kubectl create ns demo
```

## Simulation d'une application 3 tiers

Dans le namespace *demo*, vous allez déployer une application constituée de 3 Pods, chacun de ces Pods étant exposé par un service.

- Frontend

Copiez la spécification suivante dans le fichier *front.yaml*. Cette spécification définit un Pod basé sur une image contenant nginx, ainsi qu'un service de type NodePort permettant d'exposer ce Pod sur le port 30000.

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: demo
    tiers: front
  name: front
spec:
  containers:
  - image: lucj/frontend:0.1
    name: front
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: demo
    tiers: front
  name: front
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30000
  selector:
    app: demo
    tiers: front
```

Créez le Pod et le Service correspondant dans le namespace demo:

```
kubectl -n demo apply -f front.yaml
```

- Backend

Copiez la spécification suivante dans le fichier *back.yaml*. Cette spécification définit un Pod dans lequel est lancé une application python très simple qui retourne un pays au hasard (sur une request GET /random), et un service de type ClusterIP permettant d'exposer ce Pod.

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: demo
    tiers: back
  name: back
spec:
  containers:
  - image: lucj/backend:0.1
    name: back
    ports:
    - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: demo
    tiers: back
  name: back
spec:
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: demo
    tiers: back
```

Créez le Pod et le Service correspondant dans le namespace demo:

```
kubectl -n demo apply -f back.yaml
```

- Database

Copiez la spécification suivante dans le fichier *db.yaml*. Cette spécification définit un Pod basé sur *redis* et un service de type ClusterIP permettant d'exposer ce Pod.

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: demo
    tiers: db
  name: db
spec:
  containers:
  - image: redis:6.2.6
    name: db
    ports:
    - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: demo
    tiers: db
  name: db
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: demo
    tiers: db
```

Créez le Pod et le Service correspondant:

```
kubectl -n demo apply -f db.yaml
```

## Vérification

Assurez-vous que les différents Pods et Services ont bien été créés:

```
kubectl -n demo get po,svc
```

Vous devriez obtenir un résultat proche de celui ci-dessous:

```
NAME        READY   STATUS    RESTARTS   AGE
pod/front   1/1     Running   0          2m45s
pod/back    1/1     Running   0          2m45s
pod/db      1/1     Running   0          2m45s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/back    ClusterIP   10.43.168.143   <none>        80/TCP         2m45s
service/db      ClusterIP   10.43.99.62     <none>        6379/TCP       2m45s
service/front   NodePort    10.43.181.25    <none>        80:30000/TCP   2m45s
```

## Communication entre les Pods

Par défaut, tous les Pods du cluster peuvent communiquer entre eux, même si ceux-ci ne sont pas dans le même namespace. C'est ce que vous allez tester dans cette partie.

- communication entre le Pod *front* et le Pod *back*

Vérifiez, à l'aide de la commande suivante, que le Pod *front* peut joindre le serveur web qui tourne dans le Pod *back*:

```
kubectl -n demo exec front -- curl http://back/random 
```

Vous devriez obtenir une réponse montrant que le serveur est bien accessible, celui-ci renvoie une pays pris au hasard:

```
{"alpha_2":"ZA","alpha_3":"ZAF","name":"South Africa","numeric":"710"}
```

- communication entre le Pod *back* et le Pod *db*

Vérifiez, à l'aide de la commande suivante, que le Pod *back* peut joindre la db redis qui tourne dans le Pod *db* (pour illustrer cela, le Pod *back* contient un client *redis*):

```
kubectl -n demo exec back -- redis-cli -h db ping 
```

Vous devriez obtenir une réponse montrant que le serveur est bien accessible:

```
PONG
```

- communication entre le Pod *front* et le Pod *db*

Vérifiez, à l'aide de la commande suivante, que le Pod *front* peut joindre la db redis qui tourne dans le Pod *db* (pour illustrer cela, le Pod *front* contient un client *redis*):

```
kubectl -n demo exec front -- redis-cli -h db ping 
```

Comme précédemment, vous devriez obtenir une réponse montrant que la db redis est bien accessible:

```
PONG
```

- communication entre des Pods appartenant à des namespaces différents

Lancez à présent un Pod dans le namespace *default* et vérifiez que celui-ci peut communiquer avec le Pod *back* qui est dans le namespace *demo*:

```
kubectl run test --rm --restart=Never -ti --image=busybox -- wget -T 5 -q -O - http://back.demo/random
```

Note: si vous obtenez l'erreur "wget: bad address 'back.demo'", lancez la même commande en utilisant *back.demo.svc.cluster.local* à la place de *back.demo* pour indiquer le FQDN du service back. 

Vous devriez obtenir une réponse montrant que le serveur est bien accessible, celui-ci renvoie une pays pris au hasard (et supprime le Pod *test* immédiatement après)

```
{"alpha_2":"LA","alpha_3":"LAO","name":"Lao People's Democratic Republic","numeric":"418"}
pod "test" deleted
```

Note: vous pourriez également vérifier qu'un Pod lancé dans le namespace *default* peut communiquer avec les Pods *front* et *db* du namespace *demo*.

- communication vers l'extérieur

A l'aide de la commande suivante, vérifiez que le Pod *back* peut accéder au DNS de Google (IP: 8.8.8.8):

```
kubectl -n demo exec -ti back -- ping -c3 8.8.8.8
```

Vous devriez obtenir un résultat proche du suivant:

```
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: seq=0 ttl=118 time=18.508 ms
64 bytes from 8.8.8.8: seq=1 ttl=118 time=19.586 ms
64 bytes from 8.8.8.8: seq=2 ttl=118 time=18.897 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 18.508/18.997/19.586 ms
```

## NetworkPolicy - Deny all

Dans un premier temps, vous allez mettre en place une NetworkPolicy qui empêche toute communication entrantes et sortantes des Pods sélectionnés.

Créez le fichier *default-deny.yaml* contenant la spécification suivante:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny
spec:
  podSelector: {}
  policyTypes:
  - Egress
  - Ingress
```

Créez ensuite la ressource dans le namespace *demo*:

```
kubectl -n demo apply -f default-deny.yaml
```

En utilisant les différentes commandes du paragraphe précédent (*Communication entre les Pods*), vérifiez:
- que les Pods du namespaces *demo* ne peuvent plus communiquer entre eux
- qu'un Pod lancé dans le namespace *default* ne peut pas communiquer avec un Pod du namespace *demo*
- qu'un Pod du namespace *demo* ne peut pas communiquer avec l'extérieur

Vous devriez obtenir un message d'erreur pour chacune de ces commandes.

## NetworkPolicy - autorisation du DNS

Il arrive souvent que l'on autorise les Pods à accéder aux serveurs DNS. Pour cela, modifier le fichier *default-deny.yaml* de la façon suivante:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny
spec:
  podSelector: {}
  policyTypes:
  - Egress
  - Ingress
  egress:
  - ports:
    - port: 53
      protocol: TCP
    - port: 53
      protocol: UDP
```

Tous les Pods sélectionnés (Pods existants dans le namespace de la NetworkPolicy) pourront accéder au port 53 (port DNS).

Mettez ensuite à jour la NetworkPolicy:

```
kubectl -n demo apply -f default-deny.yaml
```

## Autorisation des communications front -> back

Dans le fichier *front-np.yaml* définissez une nouvelle NetworkPolicy ayant la spécification suivante. Celle-ci sélectionne le Pod *front* (Pod ayant le label *tiers: front*) et permet le trafic sortant vers le Pod *back* (Pod ayant le label *tiers: back*).

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front
spec:
  podSelector:
    matchLabels:
      tiers: front 
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tiers: back
```

Créez ensuite la ressource dans le namespace *demo*:

```
kubectl -n demo apply -f front-np.yaml
```

Vérifiez si depuis le Pod *front* il est possible de communiquer vers le Pod *back*:

```
kubectl -n demo exec front -- curl --connect-timeout 5 http://back/random
```

Vous devriez obtenir une erreur (timeout) car seul le trafic sortant du Pod *front* est autorisé. Il est également nécessaire de créer une seconde NetworkPolicy autorisant le trafic entrant du Pod *back*.

## Autorisation des communications back <- front

Dans le fichier *back-np.yaml* définissez une nouvelle NetworkPolicy ayant la spécification suivante. Celle-ci sélectionne le Pod *back* et permet le trafic entrant depuis le Pod *front*:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: back
spec:
  podSelector:
    matchLabels:
      tiers: back 
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tiers: front
```

Créez ensuite la ressource dans le namespace *demo*:

```
kubectl -n demo apply -f back-np.yaml
```

Vérifiez si depuis le Pod *front* il est maintenant possible de communiquer vers le Pod *back*:

```
kubectl -n demo exec front -- curl http://back/random
```

Vous obtiendrez cette fois un résultat similaire à celui ci-dessous:

```
{"alpha_2":"GE","alpha_3":"GEO","name":"Georgia","numeric":"268"}
```

## Autorisation des communications back <-> db

En utilisant la même approche que précédemment, utilisez des NetworkPolicy afin de permettre la communication entre le Pod *back* et le Pod *db*.

## Cleanup

Supprimez ensuite le namespace *demo* (cela supprimera l'ensemble des ressources qu'il contient):

```
kubectl delete ns demo
```

## Editeur Cilium

Les NetworkPolicy sont très utilisées pour sécuriser un cluster. L'éditeur de NetworkPolicy de Cilium est une excellente ressource pour comprendre en détails comment les NetworkPolicy sont créés. N'hésitez pas à manipuler cet outils et créer vos propres NetworkPolicy.

[Cilium NetworkPolicy Editor](https://editor.cilium.io/)