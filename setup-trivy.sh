#!/bin/bash


[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

echo "Step 1. install dependencies .. "
sudo apt-get install wget apt-transport-https gnupg lsb-release

echo "Step 2. adding pubkey .. "
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -

echo "Step 3. adding trivy's repo.. "
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list

echo "Step 4. update & install trivy .. "
sudo apt-get update
sudo apt-get install trivy