sudo apt-get update && apt-get install -y kubeadm=1.18.0-00 kubelet=1.18.0-00 kubectl=1.18.0-00
kubectl get nodes
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.18.0
kubeadm version; kubelet --version; kubectl version

