# Création d'un Pod

## Exercice

Dans cet exercice, vous allez créer une spécification pour lancer un premier Pod.

### 1. Création de la spécification

Créez un fichier yaml *whoami.yaml* définissant un Pod ayant les propriétés suivantes:
- nom du Pod: *whoami*
- image du container: *containous/whoami*
- nom du container: *whoami*

### 2. Lancement du Pod

Créez le Pod à l'aide de *kubectl*

### 3. Vérification

Listez les Pods présents et assurez vous que le Pod *whoami* apparait bien dans cette liste.

### 4. Details du Pod

Observez les détails du Pod et retrouvez l'information de l'image utilisée par le container *whoami*.

### 5. Accès à l'application via un port-forward

Utilisez la commande *kubectl port-forward* pour ouvrir le port 8888 en local et faire en sorte que le traffic qui arrive sur ce port soit redirigé sur le port 80 du pod *whoami*.

Note: si vous utilisez une machine virtuelle intermédiaire pour accéder à votre cluster, vous pourrez utiliser l'option *--address 0.0.0.0* pour la commande port-forward afin de permettre l'accès depuis toutes les interfaces réseau de votre machine.

Depuis votre navigateur accédez à l'application via le port ouvert par le port-forward.

### 6. Suppression du Pod

Supprimez le Pod.

---

## Correction

### 1. Création de la spécification

La spécification, définie dans le fichier *whoami.yaml*, est la suivante:

```
apiVersion: v1             
kind: Pod                  
metadata:
  name: whoami
spec:
  containers:
  - name: whoami
    image: containous/whoami
```

### 2. Lancement du Pod

Le Pod peut être créé avec la commande suivante:

```
kubectl apply -f whoami.yaml
```

### 3. Vérification

La commande suivante permet de lister les Pods présent:

```
kubectl get pods
```

Note: il est aussi possible de précisez *pod* (au singulier) ou simplement *po* au lieu de *pods*.

### 4. Details du Pod

Les details d'un Pod, dont l'image utilisée par le container *whoami*, peuvent être obtenus avec la commande suivante:

```
kubectl describe pod whoami
```

Note: les commandes suivantes peuvent également être utilisées:
- kubectl describe pods whoami
- kubectl describe po whoami
- kubectl describe pods/whoami
- kubectl describe pod/whoami
- kubectl describe po/whoami

Il est également possible d'obtenir la spécification du Pod avec la commande suivante dans laquelle *-o yaml* permet de spécifier le format de sortie.

```
kubectl get po/whoami -o yaml
```

### 5. Accès à l'application via un port-forward

Depuis un premier terminal lancez la commande suivante:

```
kubectl port-forward whoami 8888:80
```

Depuis un second terminal, vérifiez que l'application est accessible sur localhost depuis le port 8888:

```
$ curl localhost:8888
Hostname: whoami
IP: 127.0.0.1
IP: 10.244.1.4
RemoteAddr: 127.0.0.1:51562
GET / HTTP/1.1
Host: localhost:8888
User-Agent: curl/7.64.1
Accept: */*
``` 

### 6. Suppression du Pod

Le Pod peut etre supprimé avec la commande suivante:

```
kubectl delete po/whoami
```
