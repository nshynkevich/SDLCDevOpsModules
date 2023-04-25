#!/bin/bash


#[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1


INGRESS_REPO="https://github.com/nginxinc/kubernetes-ingress.git"
INGRESS_VERSION="v3.0.0"

if [ ! -s kubernetes-ingress ]; then
	echo "Step 1. Clone $INGRESS_REPO && checkout on $INGRESS_VERSION .. "
	git clone $INGRESS_REPO && cd kubernetes-ingress && git checkout $INGRESS_VERSION
	if [ $? -ne 0 ]; then echo "Tag '$INGRESS_VERSION' not found in $INGRESS_REPO! [ERROR]"; exit 2; fi;
else cd kubernetes-ingress;
fi; 

echo "Step 2. Installing ns and service account .. "
kubectl apply -f deployments/common/ns-and-sa.yaml

echo "Step 3. Installing RBAC .. "
kubectl apply -f deployments/rbac/rbac.yaml

echo "Step 4. Installing secret server .. "
kubectl apply -f deployments/common/default-server-secret.yaml

echo "Step 5. Installing nginx config .. "
kubectl apply -f deployments/common/nginx-config.yaml

echo "Step 6. Installing ingress class [strongly required] .. "
kubectl apply -f deployments/common/ingress-class.yaml
if [ $? -ne 0 ]; then echo "Unable to install ingress-class! [ERROR]"; exit 3; fi;

echo "Step 7. Installing ingress .. "
# add 
#          args:
#            - '-enable-custom-resources=false'
# if e.g. Failed to watch *v1.Policy: failed to list *v1.Policy: 
# the server could not find the requested resource (get policies.k8s.nginx.org)
kubectl apply -f deployments/daemon-set/nginx-ingress.yaml

echo "Step 8. Check installation .. "
kubectl get ns | grep -i ingress
if [ $? -ne 0 ]; then echo "Installation unsuccessful. Something went wrong. [ERROR]"; exit 4; fi;
kubectl get pod --namespace nginx-ingress | grep -i ingress
if [ $? -ne 0 ]; then echo "Installation unsuccessful. Something went wrong. [ERROR]"; exit 4; fi;
kubectl describe pod/$(kubectl get pods --namespace nginx-ingress --no-headers -o custom-columns=":metadata.name" | head -n 1) --namespace nginx-ingress
if [ $? -ne 0 ]; then echo "Pod(s) not found in namespace nginx-ingress. [ERROR]"; exit 4; fi;
echo "done. [OK]"
