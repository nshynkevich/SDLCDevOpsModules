#!/bin/bash

cd /tmp

apt-get update
apt-get install -y git wget vim curl

curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh 
sh get-docker.sh

exit 0