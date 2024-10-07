## Objectif

Dans cet exercice, vous aller créer une *NetworkPolicy* pour isoler un namespace en autorisant seulement les communications entre les Pods de celui-ci.

## Création de 2 namespaces

Commencez par créer 2 namespaces nommés *client1* et *client2*

```
$ kubectl create ns client1
$ kubectl create ns client2
```

## Déploiement d'un workload

Dans le namespace *client1*, vous allez créer un Deployment basé sur *nginx* et l'exposer à l'aide d'un service de type *ClusterIP* (exposition limitée à l'intérieur du cluster)

Pour cela, utilisez les commandes impératives suivantes:

```
$ kubectl create deployment www --image=nginx:1.18 --port=80 -n client1
$ kubectl expose deployment www --port=80 --target-port=80 -n client1
```

## Sans l'utilisation de NetworkPolicy

Dans le cas ou il n'y a pas de *NetworkPolicy* en place dans le namespace *client1*, il est possible depuis un Pod tournant dans un autre namespace d'accéder au Service *www* du namespace *client1*.

Nous allons illustrer ceci en lançant un Pod dans le namespace *client2*.

Lancez la commande suivante afin d'obtenir un shell intéractif dans un Pod dont l'unique container est basé sur alpine:

```
$ kubectl -n client2 run -ti test --image alpine -- sh 
```

Après avoir installé l'utilitaire *curl* (avec la commande ```apk add -u curl```), vérifiez que vous pouvez accéder au service *www* du namespace *client1*.

:fire: pour cibler un service qui tourne dans un autre namespace, il est nécessaire de postfixer le nom du service par le nom du namespace (le service *www* du namespace *client1* peut donc être référencé par *www.client1*)

```
/ # curl http://www.client1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Vous verrez donc qu'il est possible d'atteindre le Pod nginx du namespace *client1* depuis le Pod de test du namespace *client2*

## Avec l'utilisation d'une NetworkPolicy

Vous allez à présent ajouter une *NetworkPolicy* afin d'interdire aux Pods extérieur au namespace *client1* d'accèder au service *www*:

Cette *NetworkPolicy* est définie selon la spécification suivante:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
spec:
  podSelector:
    matchLabels:
  ingress:
  - from:
    - podSelector: {}
```

Cette spécification sélectionne l'ensemble des Pods du namespace (le contenu de la clé *.spec.podSelector.matchLabels est vide*) et autorise le traffic seulement depuis les autres Pods de ce même namespace.

Sauvegardez cette spécification dans le fichier *networkpolicy.yml* et créez cette ressource dans le namespace *client1*:

```
$ kubectl apply -f networkpolicy.yml -n client1
```

Comme vous l'avez fait précédemment, lancez un Pod dans le namespace *client2*. Celui-ci n'aura pas accès au service *www* tournant dans le namespace *client1*.

```
$ kubectl -n client2 run -ti newtest --image alpine -- sh
/ # apk add -u curl
...
/ # curl http://www.client1
curl: (28) Failed to connect to www.client1 port 80: Operation timed out
````

## Conclusion

Les ressources de type *NetworkPolicy* sont très importantes pour isoler les différents flux réseau au sein d'un cluster. Nous avons utilisé ici une *NetworkPolicy* très simple qui permet de faire en sorte de limiter les flux réseau entre les Pods d'un même namespace. Il est bien sur possible d'aller beaucoup plus loin et d'ajouter des règles supplémentaires afin de contrôler ces flux avec une très grande granularité.