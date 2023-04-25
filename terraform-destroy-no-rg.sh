#!/bin/bash


terraform state list | while read line; do 
	if [[ $line == azurerm_resource_group* ]]; then
		echo $line " is a resource group and will not be deleted!"
	else
		echo "deleting: " $line
		terraform destroy -target $line -auto-approve
	fi
done