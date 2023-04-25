#!/bin/bash

POLICY_FILE="$1"
POLICY_NS="$2"

if [ -z $POLICY_NS ]; then
	POLICY_NS="default";
	echo "Usage: $0 /path/to/<policy.rego> [ <ns> ]"; echo "Namespace: $POLICY_NS";
fi;
if [ -z $POLICY_FILE ]; then
	echo "Usage: $0 /path/to/<policy.rego> [ <ns> ]"; echo "Namespace: $POLICY_NS"; exit 4;
fi;
POLICY_REGO=$(basename -- "$POLICY_FILE")
POLICY="${POLICY_REGO%.*}"

echo "Creating '$POLICY' policy from $POLICY_FILE .. "
mkdir -p $HOME/.kube/policies

echo "Applying '$POLICY' policy .. ";
# To apply the policy to the cluster, need to create a ConfigMap 
# with the file contents in the opa namespace:
kubectl create configmap $POLICY --from-file=$POLICY_FILE # -n $POLICY_NS
if [ $? -ne 0 ]; then echo "Unexpected error."; exit 4; fi;
cp $POLICY_FILE $HOME/.kube/policies/ ;
echo "Policy '$POLICY' applied; Stored as $HOME/.kube/policies/$POLICY_REGO"
