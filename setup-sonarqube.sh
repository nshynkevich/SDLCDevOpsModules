#!/bin/bash

export SONAR_PWD="sonarqube"
export SONAR_USER="sonarqube"
export SONAR_PORT=9090

useradd -s /bin/bash $SONAR_USER
usermod -aG sudo $SONAR_USER
#usermod -aG wheel $SONAR_USER

echo "$SONAR_USER:$SONAR_PWD" | chpasswd

###su -m $SONAR_USER
if [ ! -d /home/$SONAR_USER ]; then
	mkdir -p /home/$SONAR_USER
	chown -R $SONAR_USER: /home/$SONAR_USER
fi 

cd /home/$SONAR_USER
###echo "Step 0: login as $SONAR_USER"

# login as sonarqube
# echo "$SONAR_PWD" | sudo -S yum install -y epel-release
# sudo yum update -y
echo "$SONAR_PWD" | sudo -S apt install -y openjdk-11-jdk vim curl wget unzip
echo "Step 1: install dependencies"
echo "$SONAR_PWD" | sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "Step 2: add postgres keys"

# Update the package lists:
sudo apt-get -y update

# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
sudo apt-get -y install postgresql php-cli php-zip

echo "Step 3: install postgresql"

PSQL_CONFIG=$(sudo find / -name pg_hba.conf 2>/dev/null)
if [ -z $PSQL_CONFIG ]; then echo "Unable to find pg_hba.conf"; exit 1; else echo "Found '$PSQL_CONFIG' OK"; fi;

sed -i -e '/^#.*/ ! s/peer/trust/g' $PSQL_CONFIG
sed -i -e '/^#.*/ ! s/ident/md5/g' $PSQL_CONFIG
echo "Step 4: edit $PSQL_CONFIG"

systemctl restart postgresql

psql -U postgres -c "CREATE USER sonarqube WITH ENCRYPTED password '$SONAR_PWD';"
psql -U postgres -c "CREATE DATABASE sonardb OWNER sonarqube;"
echo "Step 5: sonarqube db created"

wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.6.0.59041.zip
unzip sonarqube-*.zip -d /opt
mv /opt/sonarqube-* /opt/sonarqube

sed -i -e 's/#sonar.jdbc.username=/sonar.jdbc.username=sonarqube/g' /opt/sonarqube/conf/sonar.properties
sed -i -e 's/#sonar.jdbc.password=/sonar.jdbc.password=sonarqube/g' /opt/sonarqube/conf/sonar.properties
sed -i -e "s~#sonar.web.port=.*~sonar.web.port=$SONAR_PORT~g" /opt/sonarqube/conf/sonar.properties

sed -i -e 's~#sonar.jdbc.url=jdbc:postgresql.*~sonar.jdbc.url=jdbc:postgresql://localhost/sonardb~g' /opt/sonarqube/conf/sonar.properties

echo "Step 6: edit /opt/sonarqube/conf/sonar.properties"

[ -e /etc/systemd/system/sonar.service ] && rm -f /etc/systemd/system/sonar.service
echo "[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=65536
User=$SONAR_USER
Group=$SONAR_USER
Restart=always

[Install]
WantedBy=multi-user.target" | tee -a /etc/systemd/system/sonar.service
echo "Step 7: create sonar.service"

chown -R $SONAR_USER: /opt/sonarqube
#ufw allow 9000/tcp
#sysctl -w vm.max_map_count=262144
cat /etc/sysctl.conf|grep max_map_count 2>/dev/null;
if [ $? -ne 0 ]; then 
	echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.conf ; 
	sudo sysctl -p; 
else 
	echo "found $(cat /etc/sysctl.conf|grep max_map_count)"; fi


systemctl enable sonar
systemctl start sonar
echo "Step 8: restart sonar.service"

echo "Step 9: Install composer for PHP SAST scanning .. "
cd /tmp
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
echo $HASH
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
cd /opt
composer require rogervila/php-sonarqube-scanner --dev
chown -R sonarqube: vendor/ 

echo "Step 10: Install sonar-scanner .. "
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.7.0.2747-linux.zip
unzip sonar-scanner-cli-4.7.0.2747-linux.zip 
mv sonar-scanner-cli-* sonar-scanner
sed -i 's!#sonar.host.url=.*!sonar.host.url=http://localhost:9090!' conf/sonar-scanner.properties 
sed -i 's!#sonar.sourceEncoding=.*!sonar.sourceEncoding=UTF-8!' conf/sonar-scanner.properties 
cat <<EOT >> /etc/profile.d/sonar-scanner.sh
#!/bin/bash
export PATH="$PATH:/opt/sonar-scanner/bin"
EOT
echo "Remainder: sonar-scanner installed in /opt/sonar-scanner/bin"
chown -R sonarqube: sonar-scanner 


echo "Step 11: Install OWASP Dependency Check CLI .. "
cd /opt
wget https://github.com/fabpot/local-php-security-checker/releases/download/v2.0.5/local-php-security-checker_2.0.5_linux_amd64 -O local-php-security-checker
chmod +x /opt/local-php-security-checker
cp /opt/local-php-security-checker /usr/local/bin/

exit 0

