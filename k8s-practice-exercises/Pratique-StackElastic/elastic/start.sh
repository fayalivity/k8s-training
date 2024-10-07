kubectl create configmap logstash-config --from-file=./logstash.conf

kubectl create -f manifests/
