# partition details for the /var/lib/docker mountpoint
grep '/var/lib/docker\s' /proc/mounts
mountpoint -- "$(docker info -f '{{ .DockerRootDir }}')"

# ensure that only trusted users are members of the docker group.
getent group docker

# Audit all Docker daemon activities.
# audit rules for the Docker daemon
# apt-get install auditd audispd-plugins
# auditd.conf  audiit.rules
# https://1cloud.ru/help/security/audit-linux-c-pomoshju-auditd
auditctl -l | grep /usr/bin/dockerd
# auditctl -a exit,always -F path=/etc/passwd -F perm=wa
# ausearch -f /etc/passwd
# ---
# type=SYSCALL msg=audit(1531840928.084:4647): arch=c000003e syscall=82 success=yes exit=0 a0=f9d720 a1=facda0 a2=fffffffffffffe90 a3=7ffd396260e0 items=4 ppid=9580 pid=9620 auid=0 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=33 comm="vi" exe="/usr/bin/vi" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key=(null)
# ---
# ausyscall x86_64 82
###
### my .rules file -- /etc/audit/rules.d/docker-hardening.rules
###
# or add rules as adding the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/bin/dockerd -k docker
# and restart the audit daemon using the following command
# systemctl restart auditd

# Audit /run/containerd.
# an audit rule applied to the /run/containerd directory.
auditctl -l | grep /run/containerd
# Add the line as below to the /etc/audit/rules.d/docker-hardening.rules file:
# (always,exit tells auditctl that you want to audit this system call when it exits.)
## -a exit,always -F path=/run/containerd -F perm=war -k docker

# Audit /var/lib/docker (holds various certificates and keys used for TLS communication between Docker daemon and Docker client )
# verify that there is an audit rule applied to the /var/lib/docker directory
auditctl -l | grep /var/lib/docker
# Add the line as below to the /etc/audit/rules.d/docker-hardening.rules file:
## -a exit,always -F path=/var/lib/docker -F perm=war -k docker
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /etc/docker -k docker

# Audit the docker.service
# Find out the file location:
systemctl show -p FragmentPath docker.service
# if file exists:
auditctl -l | grep docker.service
# Add the line as below in /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/lib/systemd/system/docker.service -k docker
# search in log based on docker key
# ausearch --key docker

# Audit containerd.sock
#  Because this daemon runs with root privileges
# find the file 
grep 'containerd.sock' /etc/containerd/config.toml
# if exists
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /run/containerd/containerd.sock -k docker

# Audit docker.socket
# Find out the configuration file location:
systemctl show -p FragmentPath docker.socket
# Locate the socket file location:
grep ListenStream $(systemctl show -p FragmentPath docker.socket | cut -d'=' -f2)
# if the file exists, create audit rule corresponding to the file:
## -w /var/run/docker.sock -k docker
# and check
auditctl -l | grep docker.socket

# Audit /etc/default/docker
auditctl -l | grep /etc/default/docker
# Or add a rule for the /etc/default/docker file
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /etc/default/docker -k docker

# Audit /etc/docker/daemon.json
auditctl -l | grep /etc/docker/daemon.json
# if file /etc/docker/daemon.json exists and no rule
# => add a rule for the /etc/docker/daemon.json file as 
# Add the line below to the to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /etc/docker/daemon.json -k docker

# Audit /etc/containerd/config.toml
# Check audit rule present 
auditctl -l | grep /etc/containerd/config.toml
# if rule not exists then add a rule for /etc/containerd/config.toml file.
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /etc/containerd/config.toml -k docker

# Audit /etc/sysconfig/docker
auditctl -l | grep /etc/sysconfig/docker
# or add a rule for /etc/sysconfig/docker file
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /etc/sysconfig/docker -k docker

# Audit /usr/bin/containerd
auditctl -l | grep /usr/bin/containerd
# or add a rule for the /usr/bin/containerd file
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/bin/containerd -k docker

# Audit /usr/bin/containerd-shim
# (Shims are responsible for mounting the filesystem into the rootfs/ directory 
# of the bundle. Shims are also responsible for unmounting of the filesystem)
auditctl -l | grep /usr/bin/containerd-shim
# or add a rule for the /usr/bin/containerd-shim file.
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/bin/containerd-shim -k docker

# Audit /usr/bin/containerd-shim-runc-v1
auditctl -l | grep /usr/bin/containerd-shim-runc-v1
# or add a rule for the /usr/bin/containerd-shim-runc-v1 file.
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/bin/containerd-shim-runc-v1 -k docker

# Audit /usr/bin/containerd-shim-runc-v2
auditctl -l | grep /usr/bin/containerd-shim-runc-v2
# or add a rule for the /usr/bin/containerd-shim-runc-v2 file.
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/bin/containerd-shim-runc-v2 -k docker

# Audit /usr/bin/runc
auditctl -l | grep /usr/bin/runc
# or add a rule for the /usr/bin/runc file.
# Add the line below to the /etc/audit/rules.d/docker-hardening.rules file:
## -w /usr/bin/runc -k docker

# Ask administrators which benchmark we are compliant with
# && check if docker hardened accordingly

# Ensure docker version is up to date
docker version

# daemon configuration
# affect ALL container instances
# rootful: daemon mode controlled using files such as :
# 	/etc/sysconfig/docker
# 	/etc/default/docker
# 	systemd unit file or 
# 	/etc/docker/daemon.json
# rootless: change all configuration file locations + some
#	limitations regarding e.g  privileged TCP/UDP ports 

# Run the Docker daemon as a non-root user, if possible
# Rootless mode executes the Docker daemon and containers inside a user namespace, 
# with both the daemon and the container are running without root privileges:
# 	changes the location of any configuration files
# 	known limitations regarding networking and resource(s)
# check which user is managing dockerd
ps -fe | grep 'dockerd'

# Ensure network traffic is restricted between containers on the default bridge
# If not desired, restrict all inter-container communication.
# (potentially, each container can read all packets 
# across the container network on the same host.)
# 	- container linking
# 	- define custom networks 
# verify that the default network bridge (docker0) has been configured torestrict inter-container communication.
docker network ls --quiet | xargs docker network inspect --format '{{ .Name }}: {{ .Options }}' | grep --color=always enable_icc
# seach for com.docker.network.bridge.enable_icc, should be false
# if no, set "icc":false into daemon.json and 
# Send a HUP signal to the daemon to cause it to reload its configuration. 
systemctl restart docker
# or run
# 	dockerd --icc=false
# !! The --icc parameter only applies to the default docker bridge
# + capability NET_RAW should be disabled too
# !! check icc debian:latest
# !! apt update && apt install net-tools netcat tcpdump iputils-ping -y && ifconfig; tcpdump -i eth0 icmp

# Docker daemon log level == info
# review the dockerd startup options, use:
ps -ef | grep dockerd
# set log-level in daemon.json as
# 	"log-level": "info"
# or for dockerd as
# 	dockerd --log-level="info" 

# Ensure Docker is allowed to make changes to iptables
# daemon should be allowed to make changes to the iptables ruleset.
ps -ef | grep dockerd | grep iptables
# Ensure that the --iptables parameter is either not present or not set to false

# Ensure insecure registries are not used
# Docker considers a private registry either secure or insecure. 
# By default, registries are considered secure
# Secure uses TLS from /etc/docker/certs.d/<registry-name>/
# find out if any insecure registries are in use:
docker info --format 'Insecure Registries:{{.RegistryConfig.InsecureRegistryCIDRs}}' | grep -v "127.0.0.0/8"

# Ensure aufs storage driver is not used
# aufs storage driver is the oldest storage driver used on Linux systems, 
# storage driver that allows containers to share executable and shared library memory.
# known to cause some serious kernel crashes (only legay support within systems using docker)
# verify that aufs is not used as storage driver:
docker info --format 'Storage Driver: {{ .Driver }}'
# e.g. do not start Docker daemon as below:
# dockerd --storage-driver aufs

# Ensure TLS authentication for Docker daemon is configured
# !! if its required to daemon available remotely over TCP port
# By default, the Docker daemon binds to a non-networked Unix socket 
# If you change the default Docker daemon binding to a TCP port or any other
# Unix socket, anyone with access to that port or socket could have full access to the Docker
# daemon and therefore in turn to the host system
# review /etc/docker/daemon.json
# or check startup flags for /usr/bin/dockerd
ps -ef | grep dockerd | grep --color=always -E "\-\-tlsverify|\-\-tlscacert|\-\-tlscert|\-\-tlskey"

# ulimit is configured appropriately
# ulimit provides control over the resources available to the shell 
# and to processes which it starts. Setting system resource limits 
# can save you from disasters such as a fork bomb. 
check startup flags for /usr/bin/dockerd
ps -ef | grep dockerd | grep --color=always -E "\-\-default\-ulimit"
# or set for all containers
## dockerd --default-ulimit nproc=1024:2048 --default-ulimit nofile=100:200

# Enable user namespace support
# !! For example, the root user can have the expected administrative privileges 
# !! inside the container but can effectively be mapped to an unprivileged 
# !! UID on the host system
# This is beneficial where the containers do not have an explicit 
# container user defined in the container image
# or instead it
# might result in unpredictable issues or difficulty in configuration
# !! User namespace remapping is incompatible with a number of Docker 
# !! features and also currently breaks some of its functionalities. 
# 
# audit containers users
# find the PID of the container and then list the host user associated 
# with the container process
docker inspect --format='{{ .State.Pid }}' $(docker ps -q) | while read -r line; do ps -h -p "$line" -o pid,user; done
# or 
docker info --format '{{ .SecurityOptions }}'
# or add into daemon.json
## "userns-remap": "default",
# or mapping in /etc/subuid + /etc/subgid
# or start dockerd with --userns-remap <mapping>

# Ensure the default cgroup usage has been confirmed
# The --cgroup-parent option allows you to set the default 
# cgroup parent to use for all containers
# review the dockerd startup options, and ensure that the --cgroup-parent 
# parameter is either not set or is set as appropriate non-default cgroup use:
ps -ef | grep dockerd | grep --color=always -E "\-\-cgroup\-parent"

# Ensure base device size is not changed until needed
# Default base device size == 10G
# The base device size can be increased on daemon restart. Increasing 
# the base device size allows all future images and containers to be 
# of the new base device size
# review the dockerd startup options, use:
ps -ef | grep dockerd | grep --color=always -E "\-\-storage\-opt"
# you also cann add for e.g to daemon.json  
## "dm.basesize=50" 
# or start dockerd as  
## dockerd --storage-opt dm.basesize=50G
# or (affects docker command-line utility)
## docker run --storage-opt size=50G -it ubuntu:22.04 bash

# Ensure that authorization for Docker client commands is enabled
# Docker out-of-box authorization model is currently "all or nothing" == any user 
# with permission to access the Docker daemon can run any Docker client
# command. The same is true for remote users accessing Docker’s API to contact 
# the daemon.
# !! Each Docker command needs to pass through the authorization plugin mechanism. 
# !! This may have a performance impact.
ps -ef | grep dockerd | grep --color=always -E "\-\-authorization\-plugin"
# or 
# Step 1: Install/Create an authorization plugin.
# Step 2: Configure the authorization policy as desired.
# Step 3: Start the docker daemon as below:
# dockerd --authorization-plugin=<PLUGIN_ID>

# Ensure centralized and remote logging is configured
# Check current logging driver
docker info --format '{{ .LoggingDriver }}'
# Loging drivers:
# 	none	No logs are available for the container and docker logs does not return any output.
# 	local	Logs are stored in a custom format designed for minimal overhead.
# 	json-file	The logs are formatted as JSON. The default logging driver for Docker.
#	syslog	Writes logging messages to the syslog facility. The syslog daemon must be running on the host machine.
#	journald	Writes log messages to journald. The journald daemon must be running on the host machine.
#	gelf	Writes log messages to a Graylog Extended Log Format (GELF) endpoint such as Graylog or Logstash.
#	fluentd	Writes log messages to fluentd (forward input). The fluentd daemon must be running on the host machine.
#	awslogs	Writes log messages to Amazon CloudWatch Logs.
#	splunk	Writes log messages to splunk using the HTTP Event Collector.
#	etwlogs	Writes log messages as Event Tracing for Windows (ETW) events. Only available on Windows platforms.
#	gcplogs	Writes log messages to Google Cloud Platform (GCP) Logging.
#	logentries	Writes log messages to Rapid7 Logentries.

# Ensure containers are restricted from acquiring new privileges
# via suid or sgid
# process can set the no_new_priv bit in the kernel and this persists across forks, clones
# and execve. The no_new_priv bit ensures that the process and its child processes do not
# gain any additional privileges via suid or sgid bits
# check
ps -ef | grep dockerd | grep --color=always -E "\-\-no\-new\-privileges"
# set into daemon.json
# "no-new-privileges": true
# or
# dockerd --no-new-privileges

# Ensure live restore is enabled
# ~ Docker does not stop containers on shutdown or restore and that it
# properly reconnects to the container when restarted
# check
ps -ef | grep dockerd | grep --color=always -E "\-\-live\-restore"
# or
docker info --format '{{ .LiveRestoreEnabled }}'
# or in daemon.json 
# {
#  "live-restore": true
# }

# Ensure Userland Proxy is Disabled
# By default Docker daemon starts a userland proxy service for port 
# forwarding whenever a port is exposed
# 2 mechanisms for forwarding ports from the host to containers exist: 
# - Hairpin (?) NAT and 
# - userland-proxy
# check
ps -ef | grep dockerd | grep --color=always -E "\-\-userland\-proxy"
# disable via dockerd
# dockerd --userland-proxy=false
# or via daemon.json
# {
#  "userland-proxy": false
# }
# disabling userland-proxy == when container run IPTables will be user
# docker-proxy instead

# Ensure that a daemon-wide custom seccomp profile is applied if appropriate
#  custom seccomp profile instead of default one
# Many applications do not need all these system calls => custom seccomp 
# profile can be applied instead of Docker's default seccomp profile
# check the seccomp profile 
docker info --format '{{ .SecurityOptions }}'
# setup custom if required
## dockerd --seccomp-profile </path/to/seccomp/profile>

# Ensure that experimental features are not implemented 
# (Passing --experimental as a runtime flag to the docker daemon activates
# experimental features. Whilst "Experimental" is considered a stable release, it has a
# number of features which may not have been fully tested and do not guarantee API
# stability)
# check 
docker version --format '{{ .Server.Experimental }}'
# or
ps -ef | grep dockerd | grep --color=always -E "\-\-experimental"

# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################
# configs & directory permissions and ownership.
# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################

# Ensure that the docker.service file ownership is set to root:root
# docker.service file contains sensitive parameters that may alter the behavior of the
# Docker daemon. It should therefore be individually and group owned by the root user in
# order to ensure that it is not modified or corrupted by a less privileged user
# Find out the file location:
dpath=$(systemctl show -p FragmentPath docker.service | cut -d'=' -f2);
echo $dpath;if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi;else echo "$dpath not found";fi;

# Ensure that docker.service file permissions 644
# It should therefore not be writable by any other user other than root in
# order to ensure that it can not be modified by less privileged users.
dpath=$(systemctl show -p FragmentPath docker.service | cut -d'=' -f2);echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "644" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 644 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the docker.socket file ownership is set to root:root
dpath=$(systemctl show -p FragmentPath docker.socket | cut -d'=' -f2);
echo $dpath;if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that docker.socket file permissions 644
dpath=$(systemctl show -p FragmentPath docker.socket | cut -d'=' -f2);echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "644" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 644 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the /etc/docker directory ownership is set to root:root
# The /etc/docker directory contains certificates and keys in addition to various other
# sensitive files. It should therefore be individual owned and group owned by root in order
# to ensure that it can not be modified by less privileged users.
# By default, the ownership and group ownership for this directory is correctly set to root.
dpath="/etc/docker";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that /etc/docker directory permissions are set to 755
# By default, the permissions for this directory are set to 755.
dpath="/etc/docker";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "755" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 755 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found"; fi;

# Ensure that registry certificate file ownership is set to root:root
# /etc/docker/certs.d/<registry-name>
# /etc/docker/certs.d/*
dpath="/etc/docker/certs.d";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath/* | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath/*; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found."; fi;

# Ensure that registry certificate file permissions are set to 444
# Note that, by default, this directory might not exist if 
# no registry certificate files are in place
# The /etc/docker/certs.d/<registry-name> directory contains Docker registry
# certificates. These certificate files must have permissions of 444
# or more restrictive permissions in order to ensure that unprivileged users 
# do not have full access to them.
# check certs permissons (if any exist)
dpath="/etc/docker/certs.d";find "$dpath/" -type f -exec stat -c "%a %n" {} \;
# set the permissions for the registry certificate files to 444
dpath="/etc/docker/certs.d";find "$dpath/" -type f -exec chmod 0444 {} \;

# Ensure that TLS CA certificate file ownership is set to root:root
# TLS CA certificate file (the file that is passed along with the 
# --tlscacert parameter) is individually owned and group owned by root.
# It is used to authenticate the Docker server based on a given CA certificate.
ps -ef | grep dockerd | grep --color=always -E "\-\-tlscacert"
# It can be set via daemon.json as 
#     "tlscacert": "/path/to/cert/ca.pem",
cat /etc/docker/daemon.json | grep tlscacert >/dev/null; 
if [ $? -eq 0 ]; then
	tlsca=$(cat /etc/docker/daemon.json | jq '.tlscacert' | tr -d '"');
	if [[ ! -z $tlsca && -e $tlsca ]]; then
		echo "Found $tlsca certificate. Checking ownership .. ";
		stat -c %U:%G $tlsca | grep -v root:root;
		if [ $? -ne 1 ]; then 
			echo "Current ownership `stat -c %U:%G $tlsca` will be fixed.";
			sudo chown root:root $tlsca; echo "done"
		else 
			echo "Current ownership `stat -c %U:%G $tlsca` OK.";
		fi;
	else 
		echo "$tlsca certificate not found.";
	fi; else echo "$dpath not found";fi;

# Ensure that TLS CA certificate file permissions are set to 444 
cat /etc/docker/daemon.json | grep tlscacert >/dev/null; 
if [ $? -eq 0 ]; then
	tlsca=$(cat /etc/docker/daemon.json | jq '.tlscacert' | tr -d '"');
	if [[ ! -z $tlsca && -e $tlsca ]]; then
		echo "Found $tlsca certificate. Checking permissions .. ";
		if [ "$(stat -c %a $tlsca)" != "444" ]; then 
			echo "Current permissions `stat -c %a $tlsca` will be fixed.";
			sudo chmod 444 $tlsca; echo "done";
		else echo "Current permissions `stat -c %a $tlsca` OK.";
		fi;
	else 
		echo "$tlsca certificate not found.";
	fi; else echo "$dpath not found";fi;

# Ensure that Docker server certificate file ownership is set to
# root:root 
# Docker server certificate file (the file that is passed along with
# the --tlscert parameter) is individual owned and group owned by root.

# Ensure that the Docker server certificate file permissions are set to
# 444
# (--tlscert)

# Ensure that the Docker server certificate key file ownership is set to
# root:root 
# Docker server certificate key file (the file that is passed along
# with the --tlskey parameter) 
# The Docker server certificate key file should be protected from any tampering or unneeded
# reads/writes. 

# Ensure that the Docker server certificate key file permissions are set to
# 400
# (--tlskey)

# Ensure that the Docker socket file ownership is set to 
# root:docker
# The default Unix socket /var/run/docker.sock must be owned by
# root. If any other user or process owns this socket, it might be 
# possible for that non-privileged user or process to interact with 
# the Docker daemon. 
# The Docker installer creates a Unix group called docker. 
# You can add users to this group, and in this case, those users 
# would be able to read and write to the default Docker Unix socket.
# check .sock permissions (By default, the ownership and group ownership for the Docker socket file is correctly set to root:docker)
dpath="/var/run/docker.sock";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:docker;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:docker $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the Docker socket file permissions are set to 
# 660 or
dpath="/var/run/docker.sock";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "660" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 660 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found";fi;

#  Ensure that the daemon.json file ownership is set to 
# root:root
dpath="/etc/docker/daemon.json";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that daemon.json file permissions are set to 
# 644
# Therefore it should be writeable only by root to ensure it is not modified
# by less privileged users.
dpath="/etc/docker/daemon.json";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "644" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 644 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found"; fi;

# Ensure that the /etc/default/docker file ownership is set to
# root:root 
# The /etc/default/docker file contains sensitive parameters that may alter 
# the behavior of the Docker daemon. It should therefore be individually 
# owned and group owned by root to ensure that it cannot be modified by 
# less privileged users.
dpath="/etc/default/docker";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found"; fi;

# Ensure that the /etc/default/docker file permissions are set to 
# 644
# It should therefore be writeable only by root in order to ensure that it
# is not modified by less privileged users.
dpath="/etc/default/docker";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "644" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 644 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the /etc/sysconfig/docker file permissions are set to
# 644
# The /etc/sysconfig/docker file contains sensitive parameters that may alter the behavior
# of the Docker daemon.
dpath="/etc/sysconfig/docker";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then echo "$dpath found. Checking permissions .. "; 
	if [ "$(stat -c %a $dpath)" != "644" ]; then 
		echo "Current permissions `stat -c %a $dpath` will be fixed.";
		sudo chmod 644 $dpath;echo "done";
	else echo "Current permissions `stat -c %a $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the /etc/sysconfig/docker file ownership is set to
# root:root
dpath="/etc/sysconfig/docker";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the Containerd socket file ownership is set to 
# root:root
# It is a component used by Docker to create and manage containers. It
# provides a socket file similar to the Docker socket;
# but unlike the Docker socket, there is usually no requirement 
# for non-privileged users to connect to the socket, so the ownership
# should be root:root
dpath="/run/containerd/containerd.sock";echo $dpath;
if [[ ! -z "$dpath" && -e "$dpath" ]];then 
	echo "$dpath found. Checking ownership .. "; 
	stat -c %U:%G $dpath | grep -v root:root;	
	if [ $? -ne 1 ]; then 
		echo "Current ownership `stat -c %U:%G $dpath` will be fixed.";
		sudo chown root:root $dpath; echo "done";
	else 
		echo "Current ownership `stat -c %U:%G $dpath` OK.";
	fi; else echo "$dpath not found";fi;

# Ensure that the Containerd socket file permissions are set to 
# 660
# /run/containerd/containerd.sock


# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################
# Container Images and Build File Configuration
# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################

# Ensure that a user for the container has been created
# Containers should run as a non-root user.
# 	* USER directive in the Dockerfile 
# 	* through gosu or similar where used as part of the CMD or ENTRYPOINT directives.
# (The gosu utility is often used in scripts called from ENTRYPOINT instructions inside Dockerfiles for official images. It's a very simple utility, similar to sudo, that runs a given instruction as a given user. The difference is that gosu avoids sudo's "strange and often annoying TTY and signal-forwarding behavior".)
# !! run the following command
docker ps --quiet | xargs --max-args=1 -I{} docker exec {} cat /proc/1/status | grep '^Uid:' | awk '{print $3}' | grep 0;if [ $? -eq 0 ]; then echo " it returns 0, it indicates that the container process is running as root. Check running containers."; else echo "No container process(es) with UID 0 running or No containers running. OK."; fi;
# !! return the effective UID for each container and where it returns 0, it indicates
# that the container process is running as root.
# 	RUN useradd -d /home/username -m -s /bin/bash username
# 	USER username
# By default, containers are run with root privileges and also run as the root 
# user inside the container.

# Ensure that containers use only trusted base images
# use are either written from scratch or are
# based on another established and trusted base image downloaded over a secure channel.
# review the origin of each image and review its contents in
# line with your organization's security policy
# e.g. review the history
## docker history <imageName>
# trust for a specific image: 
# 	• Configure and use Docker Content trust.
# 	• View the history of each Docker image to evaluate its risk, dependent on the
# 		sensitivity of the application you wish to deploy using it.
# 	• Scan Docker images for vulnerabilities at regular intervals.

# Ensure that unnecessary packages are not installed in the container
# Containers should have as small a footprint as possible, and should not contain
# unnecessary software packages which could increase their attack surface.
declare -A osInfo;osInfo[/etc/redhat-release]="yum list installed";osInfo[/etc/arch-release]="pacman -Qe";osInfo[/etc/gentoo-release]="equery list \"*\"";osInfo[/etc/SuSE-release]="zypper packages --installed-only";osInfo[/etc/debian_version]="apt list --installed";osInfo[/etc/alpine-release]="apk list --installed";for cid in `docker ps --quiet`; do for f in ${!osInfo[@]}; do pm=$(docker exec $cid test -f $f >/dev/null; echo $?); if [ "$pm" = "0" ]; then echo $cid;echo "-----"; docker exec $cid ${osInfo[$f]};fi;done;done;

# Ensure images are scanned and rebuilt to include security patches
# Images should be scanned frequently for any vulnerabilities. 
# You should rebuild all images to include these patches and then 
# instantiate new containers from them
# For each container instance, use the package manager within the container (assuming
# there is one available) to check for the availability of security patches.
# Alternatively, run image vulnerability assessment tools to scan
declare -A osInfo;osInfo[/etc/redhat-release]="yum list-security --security";osInfo[/etc/arch-release]="echo \"no data\"; exit 1";osInfo[/etc/gentoo-release]="echo \"no data\";exit 1";
osInfo[/etc/SuSE-release]="zypper refresh && zypper list-updates";osInfo[/etc/debian_version]="apt-get -s dist-upgrade |grep '^Inst' |grep -i securi";osInfo[/etc/alpine-release]="echo \"no data\"; exit 1";for cid in `docker ps --quiet`; do echo "Checking security patches for $cid .. "; for f in ${!osInfo[@]}; do pm=$(docker exec $cid test -f $f >/dev/null; echo $?); if [ "$pm" = "0" ]; then echo $cid;echo "-----";docker exec $cid ${osInfo[$f]} ;fi;done;done;

# Ensure Content trust for Docker is Enabled
# !! Content trust is disabled by default and should be enabled in line with organizational
# security policy.
# == ability to use digital signatures for data sent to and received
# rom remote Docker registries. These signatures allow client-side verification of the
# identity and the publisher of specific image tags and ensures the provenance of container
# images
# can be set  
# 	--disable-content-trust flag 
# or
# export DOCKER_CONTENT_TRUST=1
ps -ef | grep dockerd | grep --color=always -E "\-\-disable\-content\-trust"
echo $DOCKER_CONTENT_TRUST

# Ensure that HEALTHCHECK instructions have been added to
# container images
# You should add the HEALTHCHECK instruction to your Docker container images in order to
# ensure that health checks are executed against running containers.
# == availability
# To ensure that containers are still operational.
# Based on the results of the health check, the Docker engine could terminate containers
# which are not responding correctly, and instantiate new ones.
# By default, HEALTHCHECK is not set
# check by images
echo "Is HEALTHCHECK set for all images? :";for img in `docker images -q`; do echo "$img";himg=$(docker inspect --format='{{ .Config.Healthcheck }}' $img);if [ "$himg" = "<nil>" ]; then echo "not set [X]"; else echo "set [+]";fi; done;echo "Is HEALTHCHECK set for all base images in running containers? :";for rcid in `docker ps -aq`; do rcidimg=$(docker inspect --format='{{ .Image }}' $rcid | cut -d':' -f2); rcidhimg=$(docker inspect --format='{{ .Config.Healthcheck }}' $rcidimg);if [ "$rcidhimg" = "<nil>" ]; then rcidhimgstatus="not set [X]"; else rcidhimgstatus="set [+]";fi;echo "$rcid ($rcidimg) HEALTHCHECK: $rcidhimgstatus";done;

# Ensure update instructions are not used alone in Dockerfiles
# You should not use OS package manager update instructions such as apt-get update or
# yum update either alone or in a single line in any Dockerfiles used to generate images
# under review
# Why? -- Adding update instructions in a single line on the Dockerfile will cause the update layer to
# be cached. 
# When you then build any image later using the same instruction, this will cause
# the previously cached update layer to be used, potentially preventing any fresh updates
# from being applied to later builds
# Workarounds:
# -		use --no-cache flag during docker build
# -  	use update instructions together with install instructions and version pinning
# 		for packages while installing them
# check images
echo "Is update instructon used for any image? :";for img in `docker images -q`; do echo "$img";docker history $img | grep -i update >/dev/null;if [ $? -eq 0 ]; then echo "update instructon used [X]"; else echo "update instructon NOT used [+]. OK."; fi; done;

# Ensure setuid and setgid permissions are removed
# Removing setuid and setgid permissions in the images can prevent privilege escalation
# attacks within containers.
# List all image executables which have either setuid or setgid permissions:
# docker export <IMAGE ID> | tar -tv 2>/dev/null | grep -E '^[-rwx].*(s|S).*\s[0-9]'
echo "Are executables with setuid or setgid permissions used in any running container? :";for rcid in `docker ps -aq`; do echo "$rcid";rcsgbins=$(docker export $rcid | tar -tv 2>/dev/null | grep -E '^[-rwx].*(s|S).*\s[0-9]'); if [[ ! -z $rcsgbins ]]; then echo "setuid/setgid binaries found! [X]";echo "$rcsgbins"; else echo "setuid/setgid binaries not found! [+]. OK."; fi; done;
# you could remove these permissions at build time by adding the following command in
# your Dockerfile, preferably towards the end of the Dockerfile:
## 	RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Ensure that COPY is used instead of ADD in Dockerfiles
# COPY instruction simply copies files from the local host machine to the container file system.
# ADD instruction could potentially retrieve files from remote URLs and perform
# operations such as unpacking them (if the application requires functionality
# that is part of the ADD instruction, for example, if you need to retrieve files from remote URLs)
# check if ADD instructions used in images
echo "Is ADD used for all images? :";for img in `docker images -q`; do echo "$img";docker history $img | grep ADD >/dev/null;if [ $? -eq 0 ]; then echo "ADD instructon used [X]"; else echo "ADD instructon NOT used [+]. OK."; fi; done;

# Ensure secrets are not stored in Dockerfiles
# as they will be visible to any users of the image.
# Do not store any kind of secrets within Dockerfiles
# use secrets management tool, such as the buildkit builder included with Docker.
# !! Insecure solution: COPY the secret in as a file -- layer caching: all
# 		previous layers are still present in the image.
# !! Insecure solution: Pass the secret in using –build-arg -- build arguments 
# 		are also embedded in the image: attacker can run 'docker history 
# 		--no-trunc <yourimage>' and see your secrets
# use BuildKit , add in Dockerfile
# 		RUN --mount=type=secret,id=mysecret ./build-script.sh
# Secrets are in /run/secrets so we have file /run/secrets/mysecret
# and build image as
# 		$ export DOCKER_BUILDKIT=1
# 		$ docker build --secret id=mysecret,src=secret-file .

# Ensure only verified packages are installed
# Packages with no known provenance could potentially be malicious or have
# vulnerabilities that could be exploited.
# ?? check how the authenticity of
# the packages is being determined. This could be via the use of GPG keys or other secure
# package distribution mechanisms
# Note, that binary packages are usually not signed. The integrity of a package 
# can only be confirmed by checking its hashsums against a trusted (and possibly signed) hashsum source. 
# e.g. check integrity with debsums (apt install debsums -y)
# $ dpkg -l | awk '/^ii/ { print $2 }' | xargs debsums | grep -vE 'OK$'

# Ensure all signed artifacts are validated
# Validate artifacts signatures before uploading to the package registry.
# Ensure every artifact in the package has been validated with its signature

# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################
# Container Runtime Configuration
# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################

# Ensure that, if applicable, an AppArmor Profile is enabled
# ~ security policy which is also known as an AppArmor profile. You can create your own
# AppArmor profile for containers or use Docker's default profile.
# Return a valid AppArmor Profile for each container instance:
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}):AppArmorProfile={{ .AppArmorProfile }}'
# If AppArmor is applicable for your Linux OS, you should enable it.
# 	1. Verify AppArmor is installed.
# 	2. Create or import a AppArmor profile for Docker containers.
# 	3. Enable enforcement of the policy.
# 	4. Start your Docker container using the customized AppArmor profile. For example:
# Create fiel /etc/apparmor.d/containers/my-new-docker-profile
# which contains some rules. Then
## $ sudo apparmor_parser -r -W /etc/apparmor.d/containers/my-new-docker-profile
## $ docker run --interactive --tty --security-opt="apparmor=my-new-docker-profile" ubuntu /bin/bash

# Ensure that, if applicable, SELinux security options are set
# Check, returns all the security options currently configured on the containers
# listed. Note that even if an empty SecurityOpt is returned, the MountLabel and
# ProcessLabel values will indicate if SELinux is in use
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): SecurityOpt={{ .HostConfig.SecurityOpt }} MountLabel={{ .MountLabel }} ProcessLabel={{ .ProcessLabel }}'
# Start docker with SELinux enabled
# 	$ docker daemon --selinux-enabled
# or via daemon.json
# "selinux-enabled": "true", 
# Start your Docker container using the security options. For example,
# docker run --interactive --tty --security-opt label=level:TopSecret centos /bin/bash

# Ensure that Linux kernel capabilities are restricted within containers
# ~ any process can be granted the required capabilities instead of giving it root access
# You should remove all capabilities not required for the correct function of the container.
# Audit current installed
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): CapAdd={{ .HostConfig.CapAdd }} CapDrop={{ .HostConfig.CapDrop }}'
#	add required capabilities:
## $ docker run --cap-add={"Capability 1","Capability 2"} <Run arguments> <Container Image Name or ID> <Command>
#### $ docker run --cap-add={"NET_RAW","CHOWN"} -it --rm alpine:latest /bin/sh
#### $ capsh --print
# 	remove all && add only required
## $ docker run --cap-drop=all --cap-add={"Capability 1","Capability 2"} <Run arguments> <Container Image Name or ID> <Command>
# --sysctl ~ capabilities alternative, e.g.
## $  docker run --sysctl net.ipv4.ip_forward=1 someimage
# (Adding and removing capabilities are also possible when the docker service command is used:)
## $ docker service create --cap-drop=all --cap-add={"Capability 1","Capability2"} <Run arguments> <Container Image Name or ID> <Command>)
# By default, the capabilities below are applied to containers:
# 	AUDIT_WRITE
# 	CHOWN
# 	DAC_OVERRIDE
# 	FOWNER
# 	FSETID
# 	KILL
# 	MKNOD
# 	NET_BIND_SERVICE
# 	NET_RAW
# 	SETFCAP
# 	SETGID
# 	SETPCAP
# 	SETUID
# 	SYS_CHROOT

# Ensure that privileged containers are not used
# --privileged flag provides all Linux kernel capabilities to the container to which
# it is applied and therefore overwrites the --cap-add and --cap-drop flags
# check
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Privileged={{ .HostConfig.Privileged }}'

# Ensure sensitive host system directories are not mounted on containers
# should not allow sensitive host system directories such as those listed below to be 
# mounted as container volumes, especially in read-write mode.
# 	/
# 	/boot
# 	/dev
# 	/etc
# 	/lib
# 	/proc
# 	/sys
# 	/usr
# check mounts:
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Volumes={{ .Mounts }}'
## !!  defaults to using a read-write volume 

# Ensure sshd is not run within containers
# SSH daemon should not be running within the container. You should SSH into the
# Docker host, and use docker exec to enter a container
# 	- Difficult to manage access policies and security compliance for SSH server
# 	- Difficult to manage keys and passwords across various containers
# 	- Difficult to manage security upgrades for SSH serve
## By default, SSH server is not running inside the container. Only one process per container is allowed.

# Ensure privileged ports are not mapped within containers
# TCP/IP port numbers below 1024 are considered privileged ports. 
# By default if mapping is not declared, one from 49153-65535 host ports range used.
# Declare: 1) when starting with run 2) via Dockerfile
# If declared => Docker allow a container port to be mapped to a privileged port on the host 
# because of NET_BIND_SERVICE Linux kernel capability
#  containers instances and their port mappings

# Ensure that only needed ports are open on the container
# 	- ports defined in the Dockerfile for its image 
# 	- or can alternatively be arbitrarily passed run time parameters to open a list of ports. 
# !! You can also completely ignore the list of ports defined in the Dockerfile by NOT using -P
# (UPPERCASE) or the --publish-all flag when starting the container. 
# !! Instead, use the -p (lowercase) or --publish flag to explicitly define the ports that
# you need for a container.
## $ docker run --interactive --tty --publish 5000 --publish 5001 --publish 5002 centos /bin/bash
# !! By default, all the ports that are listed in the Dockerfile under the EXPOSE instruction for an
# image are opened when a container is run with the -P or --publish-all flag
#  containers instances and their port mappings
docker ps --quiet | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Ports={{ .NetworkSettings.Ports }}'

# Ensure that the host's network namespace is not shared
#  --net=host, the container is not placed inside a separate network stack 
# == instructs Docker to not containerize the container's networking. 
# check
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): NetworkMode={{ .HostConfig.NetworkMode }}'
for rcid in `docker ps -aq`; do echo "$rcid" ;docker inspect --format '{{ .HostConfig.NetworkMode }}' $rcid | grep -i host >/dev/null;if [ $? -eq 0 ]; then echo "NetworkMode=host used [X]"; else echo "NetworkMode=host NOT used [+]. OK."; fi;done;

# Ensure that the memory usage for containers is limited
#  control the amount of memory that a container is able to use
# By default a container can use all of the memory on the host. You can use memory limit
# mechanisms to prevent a denial of service
# check
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Memory={{ .HostConfig.Memory }}'
# command returns 0, it means that memory limits are not in place; if it returns a non-zero value, it means that they are in place.
# e.g. run with restrictions
## $ docker run -d --memory 256m centos sleep 1000
# verify
## $ docker inspect --format='{{ .Config.Hostname }} ({{ .Config.Image }}): Memory={{ .HostConfig.Memory }} KernelMemory={{ .HostConfig.KernelMemory }} Swap={{ .HostConfig.MemorySwap }}' <CONTAINER ID>
## $ docker ps --quiet --all | xargs docker inspect --format='{{ .Config.Hostname }} ({{ .Config.Image }}): Memory={{ .HostConfig.Memory }} KernelMemory={{ .HostConfig.KernelMemory }} Swap={{ .HostConfig.MemorySwap }}'






docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): CpuShares={{ .HostConfig.CpuShares }}'



docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): ReadonlyRootfs={{ .HostConfig.ReadonlyRootfs }}'


#  containers instances and their port mappings
docker ps --quiet | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Ports={{ .NetworkSettings.Ports }}'


docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): RestartPolicyName={{ .HostConfig.RestartPolicy.Name }} MaximumRetryCount={{ .HostConfig.RestartPolicy.MaximumRetryCount }}'
docker run --detach --restart=on-failure:5 nginx:latest


docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): PidMode={{ .HostConfig.PidMode }}'
docker run --rm --pid=host centos ps -efxa
docker run --rm centos ps -efxa

docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): IpcMode={{ .HostConfig.IpcMode }}'
docker run -it --name=shr1 --ipc=shareable centos:latest /bin/bash
docker run -it --ipc=container:shr1 --name=shr2 centos:latest /bin/bash
df -h | grep shm
ls -la /dev/shm
touch /dev/shm/test 
# check /dev/shm/test from shr2

docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Devices={{ .HostConfig.Devices }}'
# If the above command returns [], then the container does not have access 
# to host devices and is configured in line with good security practice
# rwm (Read Write Mknod) by default if not set
# For example, do not start a container using the command below:
## $ docker run --interactive --tty --device=/dev/tty0:/dev/tty0:rwm --device=/dev/temp_sda:/dev/temp_sda:rwm centos bash
# You should only share the host device using appropriate permissions:
## $ docker run --interactive --tty --device=/dev/tty0:/dev/tty0:rw --device=/dev/temp_sda:/dev/temp_sda:r centos bash

docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Ulimits={{ .HostConfig.Ulimits }}'
# 	nofile
# 	nproc
# --ulimit is specified with a soft and hard limit as such: <type>=<soft limit>[:<hard limit>]
# e.g. 
## $ docker run --rm -it -u daemon --ulimit nproc=2 alpine /bin/sh

docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Propagation={{range $mnt := .Mounts}} {{json $mnt.Propagation}} {{end}}'
# The propagation mode should not be set to shared unless needed.
# For example, do not start a container as below:
## $ docker run <Run arguments> --volume=/hostPath:/containerPath:shared <Container Image Name or ID> <Command>
# By default, the container mounts are private.

# Ensure that the host's UTS namespace is not shared
# UTS namespaces provide isolation between two system identifiers: the hostname and the NIS domain name. 
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): UTSMode={{ .HostConfig.UTSMode }}'
# non-compliant if 'host' returned
# do not start a container using the command below:
## $ docker run --rm --interactive --tty --uts=host rhel7.2

# !! With Docker 1.10 and greater, the default seccomp profile blocks syscalls, regardless of --
# !! cap-add passed to the container. You should create your own custom seccomp profile in
# !! such cases. You may also disable the default seccomp profile by passing --security-opt=seccomp:unconfined on docker run
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): SecurityOpt={{ .HostConfig.SecurityOpt }}'

ausearch -k docker | grep exec | grep privileged

ausearch -k docker | grep exec | grep user

docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): CgroupParent={{ .HostConfig.CgroupParent }}'
# If it is blank, it means that containers are running under the default docker cgroup.

docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): SecurityOpt={{ .HostConfig.SecurityOpt }}'
# This command should return all the security options currently configured for containers.
# no-new-privileges should be one of them.
# Note that the SecurityOpt response will be empty (i.e. SecurityOpt=<no value>) even if
# 	"no-new-privileges": true 
# has been configured in the Docker daemon.json configuration file
#  should start your container with the options below:
## $ docker run --rm -it --security-opt=no-new-privileges ubuntu bash

# run the command below and ensure that all containers are reporting their health status:
docker ps --quiet | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Health={{ .State.Health }}'
# run the container using the --health-cmd parameter
## $ docker run -d --health-cmd='stat /etc/passwd || exit 1' nginx

# prevent a fork bomb --  restricting the number of forks
# run the command below and ensure that PidsLimit is not set to 0 or -1. A
# PidsLimit of 0 or -1 means that any number of processes can be forked concurrently inside
# the container
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): PidsLimit={{ .HostConfig.PidsLimit }}'

# run the command below, and verify that containers are on a user-defined
# network and not the default docker0 bridge (ulnerable to ARP spoofing and MAC flooding attacks)
docker network ls --quiet | xargs docker network inspect --format '{{ .Name }}: {{ .Options }}'

# Sharing the user namespaces of the host with the
# container does not therefore isolate users on the host from users in the containers
# run the command below and ensure that it does not return any value for
# UsernsMode. If it returns a value of host, it means that the host user namespace is shared
# with its containers.
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): UsernsMode={{ .HostConfig.UsernsMode }}'
# should not run the command below:
## $ docker run --rm -it --userns=host ubuntu bash

# docker.sock not mounted inside any container
docker ps --quiet --all | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Volumes={{ .Mounts }}' | grep docker.sock

# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################
# Docker Security Operations
# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################

docker images --quiet | xargs docker inspect --format '{{ .Config.Hostname }} ({{ .Config.Image }}): Image={{ .Config.Image }}'
# keep only the images that you actually need and establish a workflow to
# remove old or stale images from the host. 

#  retain containers that are actively in use, and delete ones which are no longer needed
docker info --format '{{ .Containers }}'
echo "Found stopped: `docker info --format '{{ .ContainersStopped }}'` running: `docker info --format '{{ .ContainersRunning }}'`"

# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################
# Docker Swarm Operations
# #######################################################################################
# #######################################################################################
# #######################################################################################
# #######################################################################################

# Do not enable swarm mode on a Docker engine instance unless this is needed
echo "Swarm status: `docker info --format '{{ .Swarm }}'`"
# If swarm mode has been enabled on a system in error, you should run the command below:
## $ docker swarm leave

# swarm managers count
# if fault tolerance is not required in the manager nodes, a single node should be elected as a
# manager. If fault tolerance is required then the smallest odd number to achieve the
# appropriate level of tolerance should be configured. This should always be an odd number
# in order to ensure that a quorum is reached. (Having an odd number of managers ensures that 
# during a network partition, there is a higher chance that the quorum remains available to 
# process requests if the network is partitioned into two sets.)
docker info --format '{{ .Swarm.Managers }}'
# or
docker node ls | grep 'Leader'
# If an excessive number of managers is configured, the excess nodes can be demoted to
# workers using the following command:
## $ docker node demote <ID>

# By default, Docker swarm services will listen on all interfaces on the host, == 
# --listen-addr flag is 0.0.0.0:2377
# By passing a specific IP address to the --listen-addr, a specific network interface can be
# specified, limiting this exposure
# check
ss -lp | grep -iE ':2377|:7946'

# By default, data exchanged between containers on nodes on the overlay network is not
# encrypted => could potentially expose traffic between containers.
docker network ls --filter driver=overlay --quiet | xargs docker network inspect --format '{{ .Name }} {{ .Options }}'
# !! You should create overlay networks the with --opt encrypted flag

# check for swarm manager node only
docker secret ls

# Ensure that swarm manager is run in auto-lock mode (Automated)
# review whether you wish to run Docker swarm manager in auto-lock mode.
# When Docker restarts, both the TLS key used to encrypt communication among swarm
# nodes, and the key used to encrypt and decrypt Raft logs on disk, are loaded into each
# manager node's memory ==> protect these keys with the --autolock flag
## $ docker swarm init --autolock
# With --autolock enabled, when Docker restarts, you must unlock the swarm first, using a
# key encryption key generated by Docker when the swarm was initialized.
docker info --format 'Swarm Autolock: {{ .Swarm.Cluster.Spec.EncryptionConfig.AutoLockManagers }}'

# autolock key should rotate periodically (can't be done automatically by docker)
docker swarm unlock-key --rotate

# rotate swarm node certificates 
# By default, node certificates are rotated every 90 days, but you should rotate them
# more often or as appropriate in your environment
# Run one of the commands below and ensure that the node certificate Expiry Duration is
# set as appropriate.
docker info | grep "Expiry Duration"
docker info --format 'NodeCertExpiry: {{ .Swarm.Cluster.Spec.CAConfig.NodeCertExpiry }}'
# run the command to set the desired expiry time on the node certificate.
docker swarm update --cert-expiry 48h

# rotate root CA certificates as appropriate
# not rotated automatically
# Node certificates depend upon root CA certificates.
# check the time stamp on the root CA certificate file
SWARM_ROOT_CA="/var/lib/docker/swarm/certificates/swarm-root-ca.crt"; [ -e $SWARM_ROOT_CA ] && ls -l $SWARM_ROOT_CA
# run the command below to rotate a certificate.
## $ docker swarm ca --rotate

# separate management plane traffic from data plane traffic.
# This requires two network interfaces per node.
# should run the command below on each swarm node and ensure that the management
# plane address is different from the data plane address.
docker node inspect --format '{{ .Status.Addr }}' self
# You should initialize the swarm with dedicated interfaces for management and data planes respectively.
## $ docker swarm init --advertise-addr=192.168.0.1 --data-path-addr=17.1.0.3




















