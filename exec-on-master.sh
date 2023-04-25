#!/bin/bash

K8S_ADVERTISE_ADDR="192.168.66.100"
K8S_POD_NET_CIDR="10.200.0.0/16"

[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

install_k8s() {
	kubeadm init --apiserver-advertise-address $K8S_ADVERTISE_ADDR --pod-network-cidr $K8S_POD_NET_CIDR
	if [ ! $? -ne 0 ]; then 
		kubeadm reset 
		echo 'Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"' >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
		systemctl daemon-reload && systemctl restart kubelet && kubeadm init
	fi 

	mkdir -p $HOME/.kube
	cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	chown $(id -u):$(id -g) $HOME/.kube/config

	# Now list nodes gives only one which is master by
	# `kubectl get nodes`, its 'STATUS' is NotReady.
	# Simply because we did not apply any network plugin.
	# flannel will be used
	local kf_url="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
	wget -q -O- $kf_url | sed s"~^[ \t]*\"Network\":.*~      \"Network\": \"$K8S_POD_NET_CIDR\",~" > kube-flannel.yaml
	kubectl apply -f kube-flannel.yaml
	kubectl get cs
	kubectl get nodes

}


install_k8s


######
# ** scheduler and/or controller unhealthy **
# In /etc/kubernetes/manifests/kube-scheduler.yaml :
# Clear the line (spec->containers->command) containing this phrase:  -- port=0
# $ systemctl restart kubelet.service

#####
# ** Install Helm
# curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
# sudo apt-get install apt-transport-https --yes
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# sudo apt-get update
# sudo apt-get install helm

######
# ** worker not joined **
# step 1:
# sudo kubeadm --v=5 token create --print-join-command 
# (this will update cluster-info.yaml with JWS in data section)
# step 2:
# run the above command on node should work.
# kubeadm join 172.16.26.136:6443 --token 0l27fp.tegcha916hiwn4lv --discovery-token-ca-cert-hash sha256:058073bb05c1d15ec802288c815e2f1d5fa12f912e6e7da9086f4b7c2e2aa850

######
# ** cidr error **
# in /etc/kubernetes/manifests/kube-controller-manager.yaml
# add in command
# 
#    - --allocate-node-cidrs=true
#    - --cluster-cidr=10.200.0.0/16
# and restart kubelet.service

######
# ** flannel error **
# sudo kubeadm reset --force;sudo ifconfig cni0 down; sudo ifconfig flannel.1 down;
# sudo ip link delete cni0; sudo ip link delete flannel.1;
# sudo ls -la /etc/cni/net.d/; echo "Removing /etc/cni/net.d/ .. "; sudo rm -rf /etc/cni/net.d/
# K8S_ADVERTISE_ADDR="192.168.66.100";K8S_POD_NET_CIDR="10.200.0.0/16";sudo kubeadm init --apiserver-advertise-address $K8S_ADVERTISE_ADDR --pod-network-cidr $K8S_POD_NET_CIDR
# sudo rm -rf ~/.kube/;mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;sudo chown $(id -u):$(id -g) $HOME/.kube/config
# if [ ! -e /tmp/kube-flannel.yaml ]; then local kf_url="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml";wget -q -O- $kf_url | sed s"~^[ \t]*\"Network\":.*~      \"Network\": \"$K8S_POD_NET_CIDR\",~" > /tmp/kube-flannel.yaml; fi
# sudo kubectl apply -f kube-flannel.yaml
# sudo kubeadm --v=5 token create --print-join-command
#


