#!/bin/bash


[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

echo "Step 1. adding ansible's source & key .. "
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main" | tee -a /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367

echo "Step 2. update & install ansible .. "
apt update
apt install ansible -y

ansible --version


echo "Step 3. download & install inspec .. "
wget https://packages.chef.io/files/stable/inspec/5.18.14/debian/10/inspec_5.18.14-1_amd64.deb -O /tmp/inspec.deb
chmod +x /tmp/inspec.deb
dpkg -i /tmp/inspec.deb
which inspec 

echo "Step 4. clone docker-baseline profile for inspec .. "
git clone https://github.com/dev-sec/cis-docker-benchmark.git
echo "Step 5. run profile with 'inspec exec cis-docker-benchmark'"