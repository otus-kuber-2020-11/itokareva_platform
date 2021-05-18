#!/bin/bash

# Отключаем swap
swapoff -a 

# Включаем маршрутизацию

cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF 
net.bridge.bridge-nf-calliptables="1" 
net.ipv4.ip_forward="1" 
net.bridge.bridge-nf-call-ip6tables="1"
EOF

# Установим docker

apt-get update && apt-get install -y \
apt-transport-https ca-certificates curl software-properties-common gnupg2

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
 "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) \
 stable"

apt-get update && apt-get install -y \
 containerd.io=1.2.13-1 \
 docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
 docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

# Setup daemon

cat > /etc/docker/daemon.json <<EOF 
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file", 
"log-opts": { "max-size": "100m" },
"storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

# Установка kubeadm, kubelet and kubectl

apt-get update && apt-get install -y apt-transport-https

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet=1.17.4-00 kubeadm=1.17.4-00 kubectl=1.17.4-00


