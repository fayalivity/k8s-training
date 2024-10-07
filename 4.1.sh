sudo apt install nfs-kernel-server
sudo mkdir /export/volumes
ll /
mkdir /export
sudo mkdir /export
sudo mkdir /export/volumes
sudo mkdir /export/volumes/pod
sudo bash -c 'echo "/export/volumes *(rw,no_root_squash,no_subtree_check)" > /etc/exports'
cat /etc/exports
sudo systemctl restart nfs-kernel-server.service
apt install nfs-common
sudo apt install nfs-common
vi nfs.pv.yaml
kc apply -f nfs.pv.yaml
kc get PersistentVolume pv-nfs-data
kc describe PersistentVolume pv-nfs-data
ll /export/volumes/pod/
vi nfs.pvc.yaml