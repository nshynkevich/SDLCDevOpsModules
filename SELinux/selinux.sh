#!/bin/bash


# setup SELinux policies how-to example
if [ `id -u` -ne 0 ]; then
	echo "Root required. Exiting .. ";
	exit 1
fi

git clone https://github.com/qyjohn/simple-lamp

mkdir -p /webapps/apps/app1 /webapps/logs /webapps/cache 

git clone https://github.com/qyjohn/simple-lamp /webapps/apps/app1

# configure lamp app
mysql -u root -e "show databases;CREATE DATABASE simple_lamp;CREATE USER 'simple'@'localhost' IDENTIFIED BY 'simple';GRANT ALL PRIVILEGES ON simple_lamp.* TO 'simple'@'localhost';show databases;exit"
cd /webapps/apps/app1 && \
mysql -u simple -p simple_lamp < simple_lamp.sql


systemctl stop apparmor && \
systemctl disable apparmor

apt update && reboot
apt-get install -y selinux-basics selinux-policy-default auditd
selinux-activate && reboot

sestatus

sepolicy manpage -a -p /usr/local/man/man8
mandb

# List control types
seinfo -t | grep httpd

# List all booleans for Apache
# semanage boolean -l | grep http

# Context
# SELinux user:Role:Type:Level

echo "Processes with httpd_t SELinux type:"
ps -eZ | grep httpd_t

# Interesting Apache context types:
# 	httpd_sys_content_t 	Read-only directories and files used by Apache
# 	httpd_sys_rw_content_t 	Readable and writable directories and files used by Apache. Assign this to directories where files can be created or modified by your application, or assign it to files directory to allow your application to modify them.
# 	httpd_log_t 			Used by Apache to generate and append to web application log files.
# 	httpd_cache_t 			Assign to a directory used by Apache for caching, if you are using mod_cache.

# Set default permissions for folder(s)
chmod g+s /webapps && \
chown -R www-data: /webapps && \
chmod -R 755 /webapps 

# Create a policy to assign the httpd_sys_content_t 
# context to the /webapps directory, and all child 
# directories and files.
semanage fcontext -a -t httpd_sys_content_t "/webapps(/.*)?"

# Create a policy to assign the httpd_log_t context 
# to the logging directories.
semanage fcontext -a -t httpd_log_t "/webapps/logs(/.*)?"

# Create a policy to assign the httpd_cache_t context
# to cache directories.
semanage fcontext -a -t httpd_cache_t "/webapps/cache(/.*)?"

# Allow users to upload files 
# Create a policy to assign the httpd_sys_rw_content_t context to 
# the upload directory, and all child files. 
semanage fcontext -a -t httpd_sys_rw_content_t "/webapps/apps/app1/uploads(/.*)?"

# Apply the SELinux policies
restorecon -Rv /webapps && ls -lZ /webapps

# View applied context(s)
semanage fcontext -E 

# or
# by oneline command
# sudo semanage fcontext -a -t httpd_sys_content_t "/webapps(/.*)?" && \
# sudo semanage fcontext -a -t httpd_log_t "/webapps/logs(/.*)?" && \
# sudo semanage fcontext -a -t httpd_cache_t "/webapps/cache(/.*)?" && \
# sudo semanage fcontext -a -t httpd_sys_rw_content_t "/webapps/apps/app1/uploads(/.*)?" && \
# sudo restorecon -Rv /webapps

# Remove fcontext(s) if smth gets wrong
# sudo semanage fcontext -d -t httpd_sys_content_t "/webapps(/.*)?" && \
# sudo semanage fcontext -d -t httpd_log_t "/webapps/logs(/.*)?" && \
# sudo semanage fcontext -d -t httpd_cache_t "/webapps/cache(/.*)?"  && \
# sudo semanage fcontext -d -t httpd_sys_rw_content_t "/webapps/apps/app1/uploads(/.*)?"

