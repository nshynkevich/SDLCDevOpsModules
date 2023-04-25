#!/bin/bash

# script install LAMP on debian
if [ `id -u` -ne 0 ]; then
	echo "Root required. Exiting .. ";
	exit 1
fi

apt update && apt install wget -y
apt install apache2 -y 
systemctl status apache2

wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb && \
apt install ./mysql-apt-config_0.8.24-1_all.deb
apt install mariadb-server -y
service mysql status
mysql_secure_installation

apt -y install lsb-release apt-transport-https ca-certificates && \
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
apt update && apt install php libapache2-mod-php php8.1-mysql php8.1-common php8.1-mysql php8.1-xml php8.1-xmlrpc php8.1-curl php8.1-gd php8.1-imagick php8.1-cli php8.1-dev php8.1-imap php8.1-mbstring php8.1-opcache php8.1-soap php8.1-zip php8.1-intl -y
php -v
echo "Edit `find /etc -name "php.ini" -type f 2>/dev/null` if needed."
