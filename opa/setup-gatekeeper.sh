#!/bin/bash


gatekeeper_install() {
	kubectl apply -f gatekeeper.yaml

}

gatekeeper_uninstall() {
	kubectl delete -f gatekeeper.yaml

	for vwh in $(kubectl get ValidatingWebhookConfiguration --no-headers -o custom-columns=":metadata.name" | grep -e "gatekeeper"); do
		kubectl delete ValidatingWebhookConfiguration/$vwh ;

	done;
	for mwh in $(kubectl get MutatingWebhookConfiguration --no-headers -o custom-columns=":metadata.name" | grep -e "gatekeeper"); do
		kubectl delete MutatingWebhookConfiguration/$mwh ;
	done; GK_NS=$(kubectl get ns --no-headers -o custom-columns=":metadata.name"|grep -e "gatekeeper"); if [ ! -z $GK_NS ]; then kubectl delete all --all -n $GK_NS; kubectl delete ns $GK_NS; fi;

}
