read -p "HOST IP ? " IP
if [ "$IP" = "" ];then
  echo "HOST IP must be provided"
  exit 1
fi

curl -s -o nginx.log https://gist.githubusercontent.com/lucj/0602e8f8ef18f949677248048365fc6b/raw

while read -r line; do curl -s -XPUT -d "$line" http://$IP:31500; done < ./nginx.log
