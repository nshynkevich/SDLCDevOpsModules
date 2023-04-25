#!/bin/bash

[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

INSTALL_VERSION="3.6.3"
INSTALLER_URL="https://mirrors.estointernet.in/apache/maven/maven-3/${INSTALL_VERSION}/binaries/apache-maven-${INSTALL_VERSION}-bin.tar.gz"

echo "Installing Maven v.${INSTALL_VERSION} .. "
echo "Download the Maven Binaries from ${INSTALL_VERSION} .. "

cd /tmp
wget -q $INSTALLER_URL
tar -xvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /opt/

echo "Setting M2_HOME and Path Variables .. "


M2_HOME='/opt/apache-maven-3.6.3'
PATH="$M2_HOME/bin:$PATH"
export PATH

mvn -version