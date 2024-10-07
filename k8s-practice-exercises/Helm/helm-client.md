## Installation du client Helm

Afin de pouvoir installer des applications packagées dans le format définit par *Helm*, vous allez installer le client *helm* en local. Pour cela, téléchargez la dernière version de la version *3* du client *helm* depuis la page de releases suivante:

[https://github.com/helm/helm/releases](https://github.com/helm/helm/releases)

Copiez ensuite le binaire *helm* dans votre *PATH*

Vérifiez que le client est correctement installé:

```
$ helm version
version.BuildInfo{Version:"v3.3.1", GitCommit:"249e5215cde0c3fa72e27eb7a30e8d55c9696144", GitTreeState:"clean", GoVersion:"go1.14.7"}
```

Installez ensuite le repository officiel contenant les charts stable, aucun repository n'étant configuré par défaut:

```
$ helm repo add stable https://charts.helm.sh/stable
```
