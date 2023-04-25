#!/bin/bash

echo "Create user(s) account(s)"
mkdir -p $HOME/.kube/users
cd $HOME/.kube/users
#MASTER_KEY=/etc/kubernetes/pki/ca.key
#MASTER_CRT=/etc/kubernetes/pki/ca.crt
MASTER_KEY=ca.key
MASTER_CRT=ca.crt
CLUSTER_NAME=kubernetes


setup_user_account_k8s() {
	local USERNAME="$1"
	local USER_GROUPS="$2"

	if [ -z $USERNAME ]; then echo "USERNAME required."; exit 1; fi;

	# user private key
	openssl genrsa -out "$USERNAME.key"
	#openssl req -new -key "$USERNAME.key" -out "$USERNAME.csr" -subj "/CN=$USERNAME"
	openssl req -new -key "$USERNAME.key" -out "$USERNAME.csr" -subj "/CN=$USERNAME$USER_GROUPS"
	openssl x509 -req -CA $MASTER_CRT -CAkey $MASTER_KEY -CAcreateserial -days 365 -in $USERNAME.csr -out $USERNAME.crt 
	if [ $? -eq 0 ]; then echo "[+] $USERNAME.crt created."; else echo "[-] Failed for $USERNAME"; exit 2; fi;

	# Set up configs with kubectl
	kubectl config set-credentials $USERNAME --client-certificate=$HOME/.kube/users/$USERNAME.crt --client-key=$HOME/.kube/users/$USERNAME.key
	if [ $? -eq 0 ]; then echo "[+] Kubernetes config set up for $USERNAME."; else echo "[-] Unable to set kubernetes config for $USERNAME"; exit 3; fi;
	kubectl config get-contexts
	kubectl config set-context "${USERNAME}-kubernetes" --cluster=$CLUSTER_NAME --user=$USERNAME # --namespace=
	if [ $? -eq 0 ]; then echo "[+] Setup context ${USERNAME}-kubernetes. OK."; else echo "[-] Setup context ${USERNAME}-kubernetes failed."; exit 4; fi;

	kubectl config get-contexts
	kubectl config use-context "${USERNAME}-kubernetes"
	kubectl config get-contexts

}

# group 		user 			ns 	res
# ops 			shark			all	all
# dev 			pewpew,shark	app	deploy, svc, ...
# observers		alice			app	readonly
#setup_user_account_k8s "shark" "/O=dev/O=ops"
#setup_user_account_k8s "alice" "/O=observers"
#setup_user_account_k8s "pewpew" "/O=dev"
