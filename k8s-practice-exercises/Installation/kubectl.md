## Installation de Kubectl

Sur la machine locale, il est nécessaire d'installer le binaire kubectl. C'est l'outil indispensable pour communiquer avec un cluster Kubernetes depuis la ligne de commande.

Son installation est très simple:

- si vous êtes sur *Linux*, utilisez les commandes suivantes:

```
VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur *macOS*, utilisez les commandes suivantes pour récupérer le binaire

```
ARCH=amd64 # ou arm64 si votre machine utilise un processor Apple (M1/M2)
VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/darwin/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur *Windows*, récupérez le binaire avec la commande suivante

```
VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/windows/amd64/kubectl.exe
```

Afin d'avoir les utilitaires comme *curl*, je vous conseille d'utiliser Git for Windows (https://gitforwindows.org), vous aurez alors Git Bash, un shell très proche de celui que l'on trouve dans un environnement Linux.

Note: si vous n'avez pas l'utilitaire *curl* vous pouvez:

- récupérer la dernière version en date de *kubectl* depuis le lien https://storage.googleapis.com/kubernetes-release/release/stable.txt

- télécharger *kubectl.exe* depuis le lien suivant (en replaçant VERSION par la valeur obtenue précédemment):
https://storage.googleapis.com/kubernetes-release/release/VERSION/bin/windows/amd64/kubectl.exe

Il vous faudra ensuite mettre kubectl.exe dans votre PATH.
