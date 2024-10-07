# Création et utilisation d'un Secret

## Exercice

Dans cet exercice vous allez utiliser un Secret pour vous connecter à une base de données externe.

### 1. Le context

L'image *registry.gitlab.com/lucj/messages:v1.0.5* contient une application simple qui écoute sur le port 3000 et permet, via des requêtes HTTP, de créer des messages ou de lister les messages existants dans une base de données *MongoDB*. L'URL de connexion de cette base doit être fournie à l'application de façon à ce que celle-ci puisse s'y connecter. Nous pouvons lui fournir via une variable d'environnement MONGODB_URL ou via un fichier qui devra être accessible depuis */app/db/mongodb_url*.

### 2. La base de données

Pour cet exercice nous allons utiliser la base de données Mongo dont l'URL de connexion est la suivante:

```
mongodb+srv://k8sExercice:k8sExercice@techwhale.hg5mrf8.mongodb.net/
```

Cette database est hostée sur [MongoDB Atlas](https://www.mongodb.com/atlas/database).

### 3. Création du Secret

Créez un Secret nommé *mongo*, le champ *data* de celui-ci doit contenir la clé *mongo_url* dont la valeur est la chaine de connection spécifiée ci-dessus.

Choisissez pour cela l'une des options suivantes:

- Option 1: utilisation de la commande `kubectl create secret generic` avec l'option `--from-file`

- Option 2: utilisation de la commande `kubectl create secret generic` avec l'option `--from-literal`

- Option 3: utilisation d'un fichier de spécification

### 4. Utilisation du Secret dans une variable d'environnement

Définissez un Pod nommé *messages-env* dont l'unique container a la spécification suivante:

- image: *registry.gitlab.com/lucj/messages:v1.0.5*
- une variable d'environnement *MONGODB_URL* ayant la valeur liée à la clé *mongo_url* du Secret *mongo* créé précédemment

Créez ensuite ce Pod et exposez le en utilisant la commande `kubectl port-forward` en faisant en sorte que le port 3000 de votre machine locale soit mappé sur le port 3000 du Pod *messages-env*.

Depuis un autre terminal, vérifiez que vous pouvez créer un message avec la commande suivante:

Note: assurez vous de remplacer *YOUR_NAME* par votre prénom

```
curl -H 'Content-Type: application/json' -XPOST -d '{"msg":"hello from YOUR_NAME"}' http://localhost:3000/messages
```

### 5. Utilisation du Secret dans un volume

Définissez un Pod nommé *messages-vol* ayant la spécification suivante:

- un volume nommé *mongo-creds* basé sur le Secret *mongo*
- un container ayant la spécification suivante:
  - image: *registry.gitlab.com/lucj/messages:v1.0.5*
  - une instructions *volumeMounts* permettant de monter la clé *mongo_url* du volume *mongo*mongo-creds* dans le fichier */app/db/mongo_url*

Créez le Pod et vérifier que vous pouvez créer un message de la même façon que dans le point précédent en exposant le Pod via un *port-forward*.

### 6. Cleanup

Supprimez les ddiférentes resources créées.

---

## Correction

### 3. Création du Secret

- Option 1: utilisation de la commande `kubectl create secret generic` avec l'option `--from-file`

Utilisez la commande suivante afin de créer un fichier *mongo_url* contenant la chaine de connexion à la base de données:

```
echo -n "mongodb+srv://k8sExercice:k8sExercice@techwhale.hg5mrf8.mongodb.net/" > mongo_url
```

Nous crééons ensuite le Secret à partir de ce fichier:

```
kubectl create secret generic mongo --from-file=mongo_url
```

- Option 2: utilisation de la commande `kubectl create secret generic` avec l'option `--from-literal`

La commande suivante permet de créer le Secret à partir de valeurs littérales

```
kubectl create secret generic mongo --from-literal=mongo_url='mongodb+srv://k8sExercice:k8sExercice@techwhale.hg5mrf8.mongodb.net/'
```

- Option 3: utilisation d'un fichier de spécification

La première étape est d'encrypter en base64 la chaine de connexion

```
$ echo -n 'mongodb+srv://k8sExercice:k8sExercice@techwhale.hg5mrf8.mongodb.net/' | base64

bW9uZ29kYitzcnY6Ly9rOHNFeGVyY2ljZTprOHNFeGVyY2ljZUB0ZWNod2hhbGUuaGc1bXJmOC5tb25nb2RiLm5ldC8=
```

Ensuite nous pouvons définir le fichier de spécification mongo-secret.yaml:

```
apiVersion: v1
kind: Secret
metadata:
  name: mongo
data:
  mongo_url: bW9uZ29kYitzcnY6Ly9rOHNFeGVyY2ljZTprOHNFeGVyY2ljZUB0ZWNod2hhbGUuaGc1bXJmOC5tb25nb2RiLm5ldC8=
```

La dernière étape consiste à créer le Secret à partir de ce fichier

```
kubectl apply -f mongo-secret.yaml
```

### 4. Utilisation du Secret dans une variable d'environnement

Nous définissons la spécification suivante dans le fichier *messages-env.yaml*

```
apiVersion: v1
kind: Pod
metadata:
  name: messages-env
spec:
  containers:
  - name: messages
    image: registry.gitlab.com/lucj/messages:v1.0.5
    env:
    - name: MONGODB_URL
      valueFrom:
        secretKeyRef:
          name: mongo
          key: mongo_url
```

Nous pouvons alors créer le Pod:

```
kubectl apply -f messages-env.yaml
```

La commande suivante permet d'exposer en localhost l'API tournant dans le container du Pod:

```
kubectl port-forward messages-env 3000:3000
```

Depuis un autre terminal de la machine locale, nous pouvons alors envoyer une requête POST sur l'API:

Note: assurez vous de remplacer *YOUR_NAME* par votre prénom

```
curl -H 'Content-Type: application/json' -XPOST -d '{"msg":"hello from YOUR_NAME"}' http://localhost:3000/messages
```

La réponse retournée est similaire à celle ci-dessous:

```
{"msg":"hello from USER_NAME","created_at":"2023-08-02T11:37:29.796Z"}
```

Nous pouvons ensuite arrêter le port-forward.

### 5. Utilisation du Secret dans un volume

Nous définissons la spécification suivante dans le fichier *messages-vol.yaml*

```
apiVersion: v1
kind: Pod
metadata:
  name: messages-vol
spec:
  containers:
  - name: messages
    image: registry.gitlab.com/lucj/messages:v1.0.5
    volumeMounts:
    - name: mongo-creds
      mountPath: "/app/db"
      readOnly: true
  volumes:
  - name: mongo-creds
    secret:
      secretName: mongo
```

:warning: si vous avez donné un autre nom que *mongo_url* à la clé du Secret (vous l'avez par exemple nommée *mongo*), vous pouvez mettre à disposition cette clé avec la configuration suivante:

```
  volumeMounts:
    - name: mongo-creds
      mountPath: "/app/db/mongo_url"
      subPath: "mongo"
```

Nous pouvons alors créer le Pod:

```
kubectl apply -f messages-vol.yaml
```

La commande suivante permet d'exposer en localhost l'API tournant dans le container du Pod:

```
kubectl port-forward messages-vol 3000:3000
```

Depuis la machine locale, nous pouvons alors envoyer une requête POST sur l'API:

```
curl -H 'Content-Type: application/json' -XPOST -d '{"msg":"hello from USER_NAME"}' http://localhost:3000/messages
```

Nous obtenons alors une réponse simimaire à la suivante:

```
{"msg":"hello from USER_NAME","created_at":"2023-08-02T11:40:26.765Z"}
```

Nous pouvons ensuite arrêter le port-forward.

### 6. Cleanup

```
k delete po messages-env messages-vol
k delete secret mongo
```