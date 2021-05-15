sudo kubeadm init --pod-network-cidr=192.168.0.0/24 > ~/kubeadm.log
tail -n2 ~//kubeadm.log > ~/join_node.sh
sed -i '1s;^;sudo ;' join_node.sh

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

