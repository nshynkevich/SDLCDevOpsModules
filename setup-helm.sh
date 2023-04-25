#!/bin/bash

[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

#####
# ** Install Helm

echo "Installing Helm .. "

echo "Adding .gpg keys(s) .. "
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null

echo "Installing dependencies .. "
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install helm

echo "Done."