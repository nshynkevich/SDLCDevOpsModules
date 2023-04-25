#!/bin/bash


step_by_step_install() {

	OPA_AC_FILE="opa_admission-controller.yaml";
	OPA_AW_FILE="opa_admission-webhook.yaml";
	OPA_DATADIR="opa-files"

	# configuring OPA
	# with kube-mgmt and Gatekeeper
	echo "Basic checks for ValidatingAdmissionWebhook & ingress .. "


	APISERVER_POD=$(kubectl get pods --namespace kube-system --no-headers -o custom-columns=":metadata.name" | grep "apiserver" | head -n 1);
	# to enable admission plugins do
	# edit /etc/kubernetes/manifests/kube-apiserver.yaml  and restart APISERVER_POD
	#kubectl exec -it kube-apiserver-master -n kube-system -- kube-apiserver --enable-admission-plugins=ValidatingAdmissionWebhook
	# Check ValidatingAdmissionWebhook is enabled
	kubectl -n kube-system describe po $APISERVER_POD | grep -i "enable-admission" | grep ValidatingAdmissionWebhook >/dev/null; 
	if [ $? -eq 0 ]; then echo "ValidatingAdmissionWebhook is enabled! [OK]";else echo "ValidatingAdmissionWebhook is disabled! [ERROR]"; fi;

	# Check ingress addon is enabled
	kubectl get pods -A | grep -i ingress >/dev/null; 
	if [ $? -eq 0 ]; then echo "ingress found! [OK]";else echo "ingress not present! [ERROR]"; fi;

	# OPA expects to load policies from ConfigMaps in the opa namespace
	kubectl create namespace opa
	echo "Kubernetes configs: "
	kubectl config get-contexts
	kubectl config set-context opa


	cd $OPA_DATADIR
	echo "Configure TLS .. "
	# Secure the communication between the API server and OPA, configure TLS:
	openssl genrsa -out opa_ca.key 2048
	openssl req -x509 -new -nodes -key opa_ca.key -days 100000 -out opa_ca.crt -subj "/CN=admission_opa_ca"
	# Generate the key and certificate for OPA
	cat >opa_server.conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOF
	openssl genrsa -out opa_server.key 2048 
	openssl req -new -key opa_server.key -out opa_server.csr -subj "/CN=opa.opa.svc" -config opa_server.conf
	openssl x509 -req -in opa_server.csr -CA opa_ca.crt -CAkey opa_ca.key -CAcreateserial -out opa_server.crt -days 100000 -extensions v3_req -extfile opa_server.conf
	# Create a Kubernetes TLS Secret to store our OPA credentials:
	kubectl create secret tls opa-server --cert=opa_server.crt --key=opa_server.key -n opa
	if [ $? -ne 0 ]; then echo "Unexpected error."; exit 2; fi;


	echo "Deploy The Admission Controller .. "
	if [ ! -e $OPA_AC_FILE ]; then echo "No $OPA_AC_FILE provided."; exit 1; fi;
	kubectl apply -f $OPA_AC_FILE ; # -n opa;
	if [ $? -ne 0 ]; then echo "Unexpected error."; exit 3; fi;



	echo "Deploy The Admission Webhook .. "
	# need an admission webhook that receives the admission HTTP callbacks and executes them
	if [ ! -e $OPA_AW_FILE ]; then echo "No $OPA_AW_FILE provided."; exit 1; fi;
	# Let's label the kube-system and opa namespaces so that they're not within the webhook scope:
	kubectl label ns kube-system openpolicyagent.org/webhook=ignore ;
	kubectl label ns opa openpolicyagent.org/webhook=ignore ;
	kubectl apply -f $OPA_AW_FILE ; # -n opa;
	if [ $? -ne 0 ]; then echo "Unexpected error."; exit 4; fi;
	echo "done. [OK]"
}

opa_uninstall () {
	for vwh in $(kubectl get ValidatingWebhookConfiguration --no-headers -o custom-columns=":metadata.name" | grep -e "opa"); do
		kubectl delete ValidatingWebhookConfiguration/$vwh ;

	done;
	for mwh in $(kubectl get MutatingWebhookConfiguration --no-headers -o custom-columns=":metadata.name" | grep -e "opa"); do
		kubectl delete MutatingWebhookConfiguration/$mwh ;
	done; OPA_NS=$(kubectl get ns --no-headers -o custom-columns=":metadata.name"|grep -e "opa"); if [ ! -z $OPA_NS ]; then kubectl delete all --all -n $OPA_NS; kubectl delete ns $OPA_NS; fi;

}









