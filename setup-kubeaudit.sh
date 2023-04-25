#!/bin/bash

[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

INSTALL_VERSION="0.21.0"
INSTALLER_URL="https://github.com/Shopify/kubeaudit/releases/download/v${INSTALL_VERSION}/kubeaudit_${INSTALL_VERSION}_linux_amd64.tar.gz"

echo "Installing kubeaudit v.${INSTALL_VERSION} .. "
echo "Download kubeaudit Binaries from ${INSTALL_VERSION} .. "

cd /tmp
wget -q $INSTALLER_URL
tar -xvf kubeaudit_${INSTALL_VERSION}_linux_amd64.tar.gz
mv kubeaudit /usr/bin/ && chmod +x /usr/bin/kubeaudit

echo "Done."