## Objectif

Dans cet exercice, vous allez installer un Ingress Controller basé sur Nginx et le configurer de façon à ce qu'il serve le domaine *country.dev* sur du https.

## Pré-requis

Assurez-vous d'avoir installé le nginx Ingress Controller comme détaillé dans [l'exercice précédent](https://gitlab.com/lucj/k8s-exercices/-/blob/master/Ingress/nginx-ingress.md).

## Application de test

Copiez la spécification suivante dans le fichier *country.yaml*. Cette spécification définit un Pod dans lequel est lancé une application python très simple qui retourne un pays au hasard (sur une request GET /random), et un service de type ClusterIP permettant d'exposer ce Pod.

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: country
  name: country
spec:
  containers:
  - image: lucj/country:1.0
    name: country
    ports:
    - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: country
spec:
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: country
```

Créez le Pod et le Service correspondant:

```
kubectl apply -f country.yaml
```

## Certificat et clé privée

Utilisez la commande suivante afin de créer un clé privée ainsiq un certificate autosigné pour le nom de domaine *country.dev*

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout cert.key -out cert.crt -subj "/CN=country.dev"
```

:warning: si vous utilisez Git-Bash, lancez la commande suivante pour générer le certificat et la clé privée (double // dans la définition du -subj)

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout cert.key -out cert.crt -subj "//CN=country.dev"
```

Créez ensuite un secret de type *tls* en lui donnant le certificat et la clé privée créées précédemment.

````
kubectl create secret tls country-certs --cert=./cert.crt --key=./cert.key
````

## Configuration du Ingress Controller

Vous allez maintenant créer la ressource Ingress qui va permettre de configurer le Ingress Controller de façon à agir en tant que terminaison TLS pour le domaine *country.dev*.

Copiez la spécification suivante dans le fichier *ingress.yaml*:

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: country
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - country.dev
    secretName: country-certs
  rules:
  - host: "country.dev"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: country
            port:
              number: 80
```

puis créez la ressource:

```
kubectl apply -f ingress.yaml
```

La section *tls* de cette spécification indique que les certificats nécessaire pour le nom de domaine *country.dev* se trouve dans la secret *country-certs* créé précédemment.

## Test

Il y a 2 cas de figure:

- 1er cas: si le Ingress Controller est exposé avec un service de type LoadBalancer, comme dans le cas ci-dessous:

```
$ kubectl get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.106.237.119   194.182.170.229   80:30810/TCP,443:31703/TCP   98s
ingress-nginx-controller-admission   ClusterIP      10.96.179.17     <none>            443/TCP                      98s
```

Modifiez votre fichier */etc/hosts* (*C:\Windows\System32\drivers\etc\hosts* sous Windows) afin d'ajouter le mapping entre le nom de domaine et l'adresse IP de votre Load Balancer. Dans l'exemple précédent il faudrait donc ajouter l'enregistrement dans ce fichier:

```
194.182.170.229 country.dev
```

Vous pouvez sinon utiliser la commande suivante afin de vérifiez que vous pouvez accéder à l'application en utilisant directement le nom de domaine *country.dev*, assurez-vous de remplacer au préalable LOAD_BALANCER_IP par l'IP de votre Load Balancer (*194.182.170.229* dans l'exemple ci-dessus).

Note: l'option *--resolve* permet de faire la résolution de nom de *country.dev

```
curl -k --resolve country.dev:443:LOAD_BALANCER_IP https://country.dev/random
```

Vous devriez obtenir un résultat similaire au résultat suivant:

```
{"alpha_2":"LA","alpha_3":"LAO","name":"Lao People's Democratic Republic","numeric":"418"}
```

- 2ème cas: si le Ingress Controller est exposé avec un service de type *NodePort*, comme dans le cas ci-dessous:

```
$ kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller-admission   ClusterIP   10.43.139.141   <none>        443/TCP                      5m14s
ingress-nginx-controller             NodePort    10.43.106.85    <none>        80:30846/TCP,443:32615/TCP   5m14s
```

Utilisez la commande suivante en remplaçant au préalable:
- *NODE-PORT* par le port permettant d'exposer le port *443* vers l'extérieur (32615 dans cet exemple) 
- *NODE_IP* par l'adresse IP d'un des nodes de votre cluster (que vous pouvez récupérer avec la commande `kubectl get no -o wide`)

```
curl -k --resolve country.dev:NODE-PORT:NODE_IP https://country.dev:NODE_PORT/random
```

Vous devriez obtenir un résultat similaire au résultat suivant:

```
{"alpha_2":"SA","alpha_3":"SAU","name":"Saudi Arabia","numeric":"682"}
```