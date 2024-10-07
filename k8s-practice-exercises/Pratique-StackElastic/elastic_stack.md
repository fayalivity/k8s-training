# La stack Elastic

Cette stack est très souvent utilisée notamment pour la gestion centralisée des logs.

Elle est composée de 3 logiciels:
- Logstash qui permet d'ingérer / filtrer / formater des données et de les envoyer à Elasticsearch
- Elasticsearch, le moteur responsable de l'indexation des données
- Kibana, l'application web permettant la visualisation et la manipulation des données

![Elastic](./images/elastic.jpeg)

## 1. But de cet exercice

Dans cet exercice, vous allez lancer une stack Elastic et configurer Logstash de façon à ce que ce dernier:
- puisse recevoir des entrées de log sur un endpoint HTTP
- ajoute des informations de reverse-geocoding à chaque entrées reçue
- envoie chaque enregistrement dans Elasticsearch

Vous enverrez ensuite des entrées de log à Logstash et les visualiserez dans l'interface de Kibana.

Dans cet exercice nous allons, dans un premier temps, déployer la stack elastic (Logstash, Elasticsearch, Kibana) en utilisant différents éléments que nous avons vu jusqu'à présent:
- Deployment
- Service
- ConfigMap

Vous pouvez faire cette manipulation sur Minikube ou un cluster Kubernetes de votre choix.

## 2. Création des fichiers manifests

Créez un nouveau répertoire, nommé *elastic* et un répertoire *manifests* dans celui-ci. Positionnez vous ensuite dans le répertoire *elastic*.

```
mkdir -p elastic/manifests
cd elastic 
```

### 2.1. Elasticsearch

#### Spécification du Deployment

La spécification suivante définit le Deployment de *elasticsearch*. Copiez celle-ci dans le fichier *manifests/deploy-elasticsearch.yaml*.

```
cat <<EOF > manifests/deploy-elasticsearch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - image: elasticsearch:7.14.2
        name: elasticsearch
        env:
        - name: ES_JAVA_OPTS
          value: -Xms512m -Xmx512m
        - name: discovery.type
          value: single-node
      initContainers:
      - name: increase-vm-max-map
        image: busybox
        command: ["sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
EOF
```


Note: la spécification du Pod contient une clé supplémentaire, *initContainers*, sous laquelle est définie une liste de containers qui seront lancés avant le container applicatif (celui basé sur l'image *elasticsearch*). L'unique container de cette liste est utilisé pour mettre à jour un paramètre du Kernel afin de permettre à Elasticsearch de se lancer correctement.

#### Specification du Service

La spécification suivante définit le Service, de type *ClusterIP*, utilisé pour exposer le Pod *elasticsearch* aux autres Pods du cluster. Copiez cette spécification dans le fichier *manifests/service-elasticsearch.yaml*.

```
cat <<EOF > manifests/service-elasticsearch.yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
spec:
  type: ClusterIP
  ports:
  - name: elasticsearch
    port: 9200
    targetPort: 9200
  selector:
    app: elasticsearch
EOF
```

### 2.2. Kibana

#### Spécification du Deployment

La spécification suivante définit le Deployment de *Kibana*. Copiez celle-ci dans le fichier *manifests/deploy-kibana.yaml*.

```
cat <<EOF > manifests/deploy-kibana.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - image: kibana:7.14.2
        name: kibana
EOF
```

#### Spécification du Service

La spécification suivante définit le Service, de type *NodePort*, utilisé pour exposer le Pod *kibana* à l'extérieur du cluster. Copiez cette spécification dans le fichier *manifests/service-kibana.yaml*.

```
cat << EOF > manifests/service-kibana.yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana
spec:
  type: NodePort
  ports:
  - port: 5601
    targetPort: 5601
    nodePort: 31501
  selector:
    app: kibana
EOF
```

### 2.3. Logstash

#### Fichier de configuration

Nous allons configurer logstash pour qu'il écoute sur HTTP, qu'il parse les entrées de logs au format apache et qu'il envoie les structures json résultantes dans *elasticsearch*. Nous allons pour cela créer le fichier *logstash.conf* dans le répertoire *elastic*. Ce fichier contient la configuration suivante:

```
cat <<EOF > logstash.conf
input {
 http {}
}

filter {
 grok {
   match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
   overwrite => [ "message" ]
 }
 mutate {
   convert => ["response", "integer"]
   convert => ["bytes", "integer"]
   convert => ["responsetime", "float"]
 }
 geoip {
   source => "clientip"
   target => "geoip"
   add_tag => [ "nginx-geoip" ]
 }
 date {
   match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
   remove_field => [ "timestamp" ]
 }
 useragent {
   source => "agent"
 }
}

output {
 elasticsearch {
   hosts => ["elasticsearch:9200"]
 }
 stdout { codec => rubydebug }
}
EOF
```

Ce fichier esst découpé en 3 parties:

- *input*: permet de spécifier les données d'entrée. Nous spécifions ici que logstash peut recevoir des données via http

- *filter*: permet de spécifier quels traitement seront appliqués aux données reçues. Plusieurs instructions sont utilisées ici:
  - grok permet de spécifier comment chaque entrée doit être parsée. De nombreux parseurs sont disponibles par défaut et nous spécifions ici (avec COMBINEDAPACHELOG) que chaque ligne doit être parsée suivant un format de log apache, cela permettra une extraction automatique des champs comme l'heure de création, l'url de la requête, l'ip d'origine, le code retour, ...
  - mutate permet de convertir les types de certains champs
  - geoip permet d'obtenir des informations géographiques à partir de l'adresse IP d'origine
  - date est utilisée ici pour reformatter le timestamp

- *output*: permet de spécifier la destination d'envoi des données une fois que celles-ci sont passées par l'étape filter. Dans le cas présent, elles seront donc envoyées au service *elasticsearch*

#### Spécification du Deployment

La spécification suivante définit le Deployment de *Logstash*. Copiez celle-ci dans le fichier *manifests/deploy-logstash.yaml*.

```
cat <<EOF > manifests/deploy-logstash.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      containers:
      - image: logstash:7.14.2
        name: logstash
        volumeMounts:
        - mountPath: /config/logstash.conf
          name: config
        command:
        - "logstash"
        - "-f"
        - "/config/logstash.conf"
      volumes:
      - name: config
        configMap:
          name: logstash-config
EOF
```

L'unique container spécifié dans le Pod utilise une *ConfigMap* afin de monter le fichier de configuration *logstash.conf* à l'emplacement lu par *logstash* par défaut (*/config/logstash.conf*)

#### Spécification du Service

La spécification suivante définit le Service utilisé pour exposer le Pod *logstash* à l'extérieur du cluster et ainsi pouvoir lui envoyer des entrées de logs. Copiez cette spécification dans le fichier *manifests/service-logstash.yaml*.

```
cat << EOF > manifests/service-logstash.yaml
apiVersion: v1
kind: Service
metadata:
  name: logstash
spec:
  type: NodePort
  ports:
  - name: logstash
    port: 8080
    targetPort: 8080
    nodePort: 31500
  selector:
    app: logstash
EOF
```

## 3. Création d'une ConfigMap pour configurer Logstash

Depuis un shell dans le répertoire *elastic*, lancez la commande suivante pour créer la configMap *logstash-config*. Celle-ci est créée à partir du fichier de configuration *logstash.conf* que nous avons défini précédemment.

```
$ kubectl create configmap logstash-config --from-file=./logstash.conf
```

La commande suivante permet de vérifiez le contenu de la ConfigMap que vous venez de créer:

```
$ kubectl get cm/logstash-config -o yaml
```

Vous devriez obtenir un résultat proche de celui ci-dessous dans lequel le contenu du fichier *logstash.conf* apparait sous la clé du même nom.

```
apiVersion: v1
data:
  logstash.conf: |
    input {
     http {}
    }

    filter {
     grok {
       match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
       overwrite => [ "message" ]
     }
     mutate {
       convert => ["response", "integer"]
       convert => ["bytes", "integer"]
       convert => ["responsetime", "float"]
     }
     geoip {
       source => "clientip"
       target => "geoip"
       add_tag => [ "nginx-geoip" ]
     }
     date {
       match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
       remove_field => [ "timestamp" ]
     }
     useragent {
       source => "agent"
     }
    }

    output {
     elasticsearch {
       hosts => ["elasticsearch:9200"]
     }
     stdout { codec => rubydebug }
    }
kind: ConfigMap
metadata:
  creationTimestamp: "2019-09-06T17:39:54Z"
  name: logstash-config
  namespace: default
  resourceVersion: "7353"
  selfLink: /api/v1/namespaces/default/configmaps/logstash-config
  uid: ec61380a-b394-4ca6-bc52-15c851d6510e
```


## 4. Déploiement de l'application

Note: afin que Elasticsearch puisse se lancer correctement, il est nécessaire d'augmenter la mémoire virtuelle de la machine hôte, ceci est effectué par le container d'init du Pod elasticsearch.

Depuis un shell dans le répertoire *elastic*, lancez l'application avec la commande suivante:

```
$ kubectl apply -f manifests/
deployment "elasticsearch" created
deployment "kibana" created
deployment "logstash" created
service "elasticsearch" created
service "kibana" created
service "logstash" created
```

On peut alors vérifier que les différents Deployments, Pods et Services ont bien été créés et que les Pods ont le status *Running*. Cela peut prendre quelques dizaines de secondes car les images doivent d'abord être téléchargées depuis le Docker Hub.

```
$ kubectl get svc,deploy,pod
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/elasticsearch   ClusterIP   10.245.221.158   <none>        9200/TCP         2m25s
service/kibana          NodePort    10.245.241.64    <none>        5601:31501/TCP   2m25s
service/kubernetes      ClusterIP   10.245.0.1       <none>        443/TCP          88m
service/logstash        NodePort    10.245.56.41     <none>        8080:31500/TCP   2m25s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/elasticsearch   1/1     1            1           2m25s
deployment.extensions/kibana          1/1     1            1           2m25s
deployment.extensions/logstash        1/1     1            1           2m25s

NAME                                 READY   STATUS    RESTARTS   AGE
pod/elasticsearch-577ff589c5-cvrgl   1/1     Running   0          2m25s
pod/kibana-756d67774f-mnp8n          1/1     Running   0          2m25s
pod/logstash-779b98c567-42fhz        1/1     Running   0          2m25s
```

## 5. Test de la stack Elastic

Nous allons maintenant utiliser un fichier de log de test et envoyer son contenu dans Logstash, contenu qui sera filtré et envoyé à Elasticsearch.

Nous lançons pour cela un Pod basé sur l'image *mingrammer/flog* afin de générer 1000 entrées de log:

```
$ kubectl run testlog --restart=Never --image=mingrammer/flog -- -f apache_combined
```

Attendez que le Pod soit dans l'état *Completed* (ça ne devrait prendre que quelques secondes):

```
$ k get -w pods
NAME      READY   STATUS              RESTARTS   AGE
testlog   0/1     ContainerCreating   0          1s
testlog   1/1     Running             0          5s
testlog   0/1     Completed           0          5s
```

En utilisant la commande suivante, récupérez ensuite les logs qui ont été générés:

```
$ kubectl logs testlog > nginx.log
```

Assurez-vous tout d'abord que l'interface de *Kibana* est disponible, cela permet d'être sur que *Elasticsearch* a fini de démarrer et que *Kibana* a pu s'y connecter. Vous devriez obtenir l'interface suivante en utilisant l'adresse IP de l'une des machines du cluster et le port 31501.

![Kibana](./images/kibana-1.png)

Cliquez sur "Explore on my own"

![Kibana](./images/kibana-2.png)

Ouvrez le menu de gauche et sélectionnez "Discover":

![Kibana](./images/kibana-3.png)

Dans un premier temps il faut créer un index en suivant les instructions suivantes:

![Kibana](./images/kibana-4.png)

![Kibana](./images/kibana-5.png)

![Kibana](./images/kibana-6.png)

![Kibana](./images/kibana-7.png)

Utilisez ensuite la commande suivante pour envoyer chaque ligne à Logstash (assurez vous de remplacer *HOST* par l'adresse IP de l'une des machines du cluster):

- Si vous êtes sur Linux / MacOS

```
while read -r line; do curl -s -XPUT -d "$line" http://HOST:31500; done < ./nginx.log
```

- Si vous êtes sur Windows et que vous utilisez Powershell

```
foreach($line in Get-Content .\nginx.log) {
  curl -s -XPUT -d "$line" http://HOST:31500;
}
```

Retourner sur l'interface de Kibana et cliquez sur *Discover*

![Kibana](./images/kibana-8.png)

Vous pourrez alors créer un dashboard afin d'avoir une interprétation visuelle des logs

![Kibana](./images/kibana-9.png)

![Kibana](./images/kibana-10.png)

A l'intérieur de celui-ci créez une visualisation

![Kibana](./images/kibana-11.png)

Vous pourrez alors ajouter les champs que vous souhaitez par un simple glisser-déposer et obtenir une visualisation comme celle ci-dessous:

![Kibana](./images/kibana-12.png)

Manipulez l'interface pour créer différentes visualisations.

Supprimer ensuite la stack Elastic ainsi que le pod testlog:

```
kubectl delete -f manifests
kubectl delete po testlog
```

## Résumé

Il est relativement simple de mettre en place une stack Elastic sur un cluster Kubernetes (cela deviendrait un peu plus compliqué si l'on souhaitait configurer un cluster Elasticsearch). Nous verrons dans un autre exercice comment utiliser cette stack pour la gestion centralisée des logs (logs provenant du cluster ainsi que les logs applicatifs).
