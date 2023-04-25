#!/bin/bash

[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

INSTALL_VERSION="2.11.1"
INSTALLER_URL="https://github.com/zaproxy/zaproxy/releases/download/v$INSTALL_VERSION/ZAP_${INSTALL_VERSION}_Linux.tar.gz"
cd /tmp
wget -q $INSTALLER_URL
tar -xzvf "ZAP_${INSTALL_VERSION}_Linux.tar.gz"
[ -e /opt/zaproxy ] && rm -fr /opt/zaproxy
rsync -av "ZAP_${INSTALL_VERSION}"/ /opt/zaproxy/

[ -e /usr/bin/zaproxy ] && rm -f /usr/bin/zaproxy 
cat <<EOT >> /usr/bin/zaproxy
#!/bin/sh 

cd /opt/zaproxy
exec ./zap.sh -daemon
EOT
chmod +x /usr/bin/zaproxy

echo "Creating OWASP ZAP systemd service (zaproxy.service) .. "
useradd -m -d /home/zaproxy -s /bin/false zaproxy
cat <<EOT >> /etc/systemd/system/zaproxy.service
[Unit]
Description=OWASP ZAP
After=multi-user.target
Conflicts=getty@tty1.service

[Service]
Type=simple
User=zaproxy
WorkingDirectory=/home/zaproxy/
ExecStart=/usr/bin/zaproxy
StandardInput=tty-force

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable zaproxy
systemctl start zaproxy
systemctl status zaproxy
