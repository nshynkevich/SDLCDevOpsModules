#!/bin/bash

setup_binary() {

	[ `id -u` -ne 0 ] && echo "Root required. Exiting .. " && exit 1

	INSTALL_VERSION="0.6.10"
	INSTALLER_URL="https://github.com/aquasecurity/kube-bench/releases/download/v${INSTALL_VERSION}/kube-bench_${INSTALL_VERSION}_linux_amd64.tar.gz"

	echo "Installing kube-bench v.${INSTALL_VERSION} .. "
	echo "Download kube-bench Binaries from ${INSTALL_VERSION} .. "

	cd /tmp
	wget -q $INSTALLER_URL
	tar xzf kube-bench_${INSTALL_VERSION}_linux_amd64.tar.gz
	mv kube-bench /usr/bin/ && chmod +x /usr/bin/kube-bench

	echo "Done."
}

setup_k8s_job() {
	local KBJ_YAML="$1"
	if [[ -z $KBJ_YAML || ! -e $KBJ_YAML ]]; then 
		local KBJ_LOAD="https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml";
		local KBJ_LOAD="https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-master.yaml";
		echo "Installing kube-bench from $KBJ_LOAD .. ";
		kubectl apply -f $KBJ_LOAD;
	else 
		echo "Installing kube-bench from $KBJ_YAML .. ";
		kubectl apply -f $KBJ_YAML;
	fi;
}

setup_k8s_job "$1"