#!/bin/bash

# The variables below setup in env.sh
subscriptionID=""
aksClusterName=""
aksClusterRegion=""
aksNodepoolName=""
resourceGroupName=""
#resourceGroupFullName=""
storageAccountName=""
shareName=""
aksPublicIPResourceName=""
clientID=""
source ./env.sh

run_once_fs() {
	# az storage account list
	az storage account create \
	    --resource-group $resourceGroupName \
	    --name $storageAccountName \
   		--kind StorageV2 \
    	--sku Standard_ZRS \
    	--output none
}

create_fs() {
		
	az storage share-rm create \
    	--resource-group $resourceGroupName \
    	--storage-account $storageAccountName \
    	--name $shareName \
    	--access-tier "TransactionOptimized" \
    	--quota 5 \
    	--output none
}

delete_fs() {
	# az storage account keys list --resource-group my_mentoring_rg_north --account-name mymentoringstac
	# az storage share list --account-key "abcdkey" --account-name mymentoringstac
	local storageAccountName="$1" ; 
	if [ -z $storageAccountName ]; then
		echo "error: storageAccountName not set. Nothing to do." ;
		exit 2;
	fi ;
	az storage share delete \
    	--name <yourFileShareName> \
    	--account-name $storageAccountName ;
}

create_static_ip() {
	local mode="$1" ;

	# 1. Get the name of the resource group where AKS node pools are deployed
	local resourceGroupFullName=$(az aks show \
	    --resource-group $resourceGroupName \
	    --name $aksClusterName \
	    --query nodeResourceGroup \
	    --output tsv) ;

	if [ -z $resourceGroupFullName ]; then 
		echo "Unable to get resource group where AKS node pools are deployed. Exit. "; 
		exit 2; 
	fi ;

	# 2. Get the names of the AKS cluster node pools that we need to check AN property for
	az aks nodepool list \
		--resource-group $resourceGroupFullName \
		--cluster-name $aksClusterName \
		--query "[].{Name:name}"

	# 3. For each node pool, check if Accelerated Networking is enabled on a VMSS level 
	az vmss show \
		--name $aksNodepoolName \
		--resource-group $resourceGroupFullName \
		--query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[].enableAcceleratedNetworking"

	if [[ "$mode" == "create" ]]; then
		az network public-ip create \
			--resource-group $resourceGroupFullName \
	    	--name $aksPublicIPResourceName \
	    	--sku Standard \
	    	--allocation-method static ;
	fi ;

	az network public-ip show \
		--resource-group $resourceGroupFullName \
	    --name $aksPublicIPResourceName \
	    --query ipAddress \
	    --output tsv ;
}

create_lb() {
	az aks create \
		--resource-group $resourceGroupName \
		--name aksClusterName \
		--load-balancer-sku basic
}

service_k8s_aks() {
	# create role assignment first of all
	az role assignment create \
		--assignee $clientID \
		--role "Network Contributor" \
		--scope "/subscriptions/$subscriptionID/resourceGroups/${resourceGroupName}_${aksClusterName}_${aksClusterRegion}"
}

create_lb
exit
create_static_ip test
#run_once_fs
#create_fs