## ------------
## 644
## ------------
stat -c %a /etc/kubernetes/manifests/kube-apiserver.yaml
stat -c %a /etc/kubernetes/manifests/kube-controller-manager.yaml
# is the kubeconfig file for the Scheduler ( control plane process which assigns Pods to Nodes)
stat -c %a /etc/kubernetes/manifests/kube-scheduler.yaml
# etcd is a highly- available key-value store which Kubernetes uses for persistent storage of all of its REST API object
stat -c %a /etc/kubernetes/manifests/etcd.yaml
# Container Network Interface e.g. flannel
stat -c %a /etc/cni/net.d/10-flannel.conflist
# admin.conf file contains the admin credentials for the cluster
stat -c %a /etc/kubernetes/admin.conf
stat -c %a /etc/kubernetes/scheduler.conf
# is the kubeconfig file for the Controller Manager (daemon embeds non-terminating loop that regulates the state of the system == watches the shared state of the cluster through the apiserver and makes changes attempting to move the current state towards the desired state)
stat -c %a /etc/kubernetes/controller-manager.conf
ls -laR /etc/kubernetes/pki/*.crt


## ------------
## 600
## ------------
ls -laR /etc/kubernetes/pki/*.key

## ------------
## root:root
## ------------
stat -c %U:%G /etc/kubernetes/manifests/kube-apiserver.yaml
stat -c %U:%G /etc/kubernetes/manifests/kube-controller-manager.yaml
stat -c %U:%G /etc/kubernetes/manifests/kube-scheduler.yaml
stat -c %U:%G /etc/kubernetes/manifests/etcd.yaml
stat -c %U:%G /etc/cni/net.d/10-flannel.conflist
stat -c %U:%G /etc/kubernetes/admin.conf
stat -c %U:%G /etc/kubernetes/scheduler.conf
stat -c %U:%G /etc/kubernetes/controller-manager.conf
ls -laR /etc/kubernetes/pki/

## ------------
## 700
## ------------
# On the etcd server node, get the etcd data directory, passed as an argument --data-dir, from the below command:
ETCD_DATADIR=$(ps -ef | grep etcd | grep -o "\-\-data\-dir=.*" |cut -d ' ' -f1|cut -d '=' -f2);echo $ETCD_DATADIR;stat -c %a  $ETCD_DATADIR 

## ------------
## etcd:etcd
## ------------
ETCD_DATADIR=$(ps -ef | grep etcd | grep -o "\-\-data\-dir=.*" |cut -d ' ' -f1|cut -d '=' -f2);echo $ETCD_DATADIR;stat -c %U:%G  $ETCD_DATADIR 

## ------------
## false or not set
## ------------
# disallow anonymous requests --anonymous-auth=false
# By default, anonymous access is enabled.
ps -ef | grep kube-apiserver | grep -o "\-\-anonymous\-auth=.*" 

# Do not allow all requests.
ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $AP;if [[ "$AP" == *"AlwaysAdmit"* ]]; then echo "[ Failed ] AlwaysAdmit included."; else  echo "[ Passed ] AlwaysAdmit not found. OK."; fi;

# Do not use basic authentication --basic-auth-file not set (as it 
# - uses uses plaintext credentials for authentication
# - basic authentication credentials last indefinitely
# - password cannot be changed without restarting the API server
# By default, basic authentication is not set.
 ps -ef | grep kube-apiserver | grep "\-\-basic\-auth\-file"

# Do not use token based authentication --token-auth-file not set
# utilizes static tokens (not set by default)
# - in cleartext
# - cannot be revoked or rotated without restarting the apiserver
 ps -ef | grep kube-apiserver | grep "\-\-token\-auth\-file"

# Do not bind the insecure API service (not set by default) 
# anyone who could connect to it over the insecure port, would have unauthenticated and unencrypted access to your master node
ps -ef | grep kube-apiserver | grep -o "\-\-insecure\-bind\-address=.*" >/dev/null;if [ $? -eq 1 ]; then echo "[ Passed ] InsecureBind Check OK."; else echo "[ Failed ]  --insecure-bind-address found."; fi;

# Disable profiling, if not needed (set by default)
# Profiling allows for the identification of specific performance bottlenecks
ps -ef | grep kube-apiserver | grep -o "\-\-profiling=false" >/dev/null;if [ $? -eq 0 ]; then echo "[ Passed ] kube-apiserver Profiling Disabled. OK."; else echo "[ Failed ] kube-apiserver --profiling default or set to true."; fi;

# Disable profiling, if not needed (set by default)
# Profiling information would not be available.
ps -ef | grep kube-controller-manager | grep -o "\-\-profiling=false" >/dev/null;if [ $? -eq 0 ]; then echo "[ Passed ] kube-controller-manager Profiling Disabled. OK."; else echo "[ Failed ] kube-controller-manager --profiling default or set to true."; fi;

# Disable profiling, if not needed (set by default)
# Profiling information would not be available.
ps -ef | grep kube-scheduler | grep -o "\-\-profiling=false" >/dev/null;if [ $? -eq 0 ]; then echo "[ Passed ] kube-scheduler Profiling Disabled. OK."; else echo "[ Failed ] kube-scheduler --profiling default or set to true."; fi;







## ------------
## true or set
## ------------
# https for kubelet connections (set by default)
ps -ef | grep kube-apiserver | grep "\-\-kubelet\-https"

# Limit the rate at which the API server accepts requests (not set by default)
# Verify set to a value that includes EventRateLimit.
ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $AP;if [[ "$AP" == *"EventRateLimit"* ]]; then echo "[ Passed ] EventRateLimit found. OK."; else echo "[ Failed ] EventRateLimit not included."; fi; 

# Enable certificate based kubelet authentication.
# i.e apiserver Must authenticate itself to the kubelet's HTTPS endpoints.
ps -ef | grep kube-apiserver | grep -e "\-\-kubelet\-client\-certificate" -e "\-\-kubelet\-client\-key";KLETCC=$(ps -ef | grep kube-apiserver | grep -o "\-\-kubelet\-client\-certificate=.*" |cut -d ' ' -f1|cut -d '=' -f2);KLETCK=$(ps -ef | grep kube-apiserver | grep -o "\-\-kubelet\-client\-key=.*" |cut -d ' ' -f1|cut -d '=' -f2);[ -e $KLETCC ] && echo "[ Passed ] $KLETCC OK";[ -e $KLETCK ] && echo "[ Passed ] $KLETCK OK";

# Verify kubelet's certificate before establishing connection.
ps -ef | grep kube-apiserver | grep -e "\-\-kubelet\-certificate\-authority"

# Always pull images.
ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $AP;if [[ "$AP" == *"AlwaysPullImages"* ]]; then echo "[ Passed ]"; else echo "[ Failed ] AlwaysPullImages not included."; fi; 

# Limit the Node and Pod objects that a kubelet could modify (not set by default)
ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $AP;if [[ "$AP" == *"NodeRestriction"* ]]; then echo "[ Passed ] NodeRestriction found. OK."; else echo "[ Failed ] NodeRestriction not included."; fi; 

# SecurityContextDeny used to deny pods which make use of some SecurityContext fields (not set by default)
# which could allow for privilege escalation in the cluster (when PodSecurityPolicy unset)
ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-enable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2);echo $AP;if [[ "$AP" == *"PodSecurityPolicy"* ]]; then echo "[ Passed ] PodSecurityPolicy founud. OK."; else echo "[ Failed ] PodSecurityPolicy not included."; if [[ "$AP" == *"SecurityContextDeny"* ]]; then echo "[ Passed ] SecurityContextDeny found. OK."; else echo "[ Failed ] SecurityContextDeny not included"; fi; fi; 

# Automate service accounts management (must be disabled) (set by default)
# When you create a pod, if you do not specify a service account, it is automatically assigned the default service account in the same namespace.
ps -ef | grep kube-apiserver | grep -o "\-\-disable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-disable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $AP;if [[ "$AP" == *"ServiceAccount"* ]]; then echo "[ Passed ] ServiceAccount disabled. OK."; else echo "[ Failed ] ServiceAccount is probably enabled."; fi; 

# Reject creating objects in a namespace that is undergoing termination. (set by default)
ps -ef | grep kube-apiserver | grep -o "\-\-disable\-admission\-plugins.*";AP=$(ps -ef | grep kube-apiserver | grep -o "\-\-disable\-admission\-plugins.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $AP;if [[ "$AP" != *"NamespaceLifecycle"* ]]; then echo "[ Passed ] NamespaceLifecycle not in Disabled. OK."; else echo "[ Failed ] NamespaceLifecycle is probably disabled."; fi; 

# Enable auditing on the Kubernetes API Server and set the desired audit log path (not set by default)
ps -ef | grep kube-apiserver | grep -o "\-\-audit\-log\-path.*";ALP=$(ps -ef | grep kube-apiserver | grep -o "\-\-audit\-log\-path.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $ALP;if [[ -z "$ALP" || ! -e $ALP ]]; then echo "[ Failed ] Auditing is probably disabled."; else echo "[ Passed ] Audit log to $ALP. OK."; fi; 

# Validate service account before validating token (true by default)
# if not enabled it allows to useing service account even after corresponding user is deleted
ps -ef | grep kube-apiserver | grep -o "\-\-service\-account\-lookup.*";SAL=$(ps -ef | grep kube-apiserver | grep -o "\-\-service\-account\-lookup.*"|cut -d ' ' -f1|cut -d '=' -f2); echo $SAL;if [[ "$SAL" != "true" ]]; then  echo "[ Failed ] ServiceAccountLookup (validation) is probably disabled."; else echo "[ Passed ] ServiceAccountLookup (validation) is enabled. OK."; fi; 

# set a service account public key file for service accounts on the apiserver (not set by default)
ps -ef | grep kube-apiserver | grep -e "\-\-service\-account\-key\-file";SAKF=$(ps -ef | grep kube-apiserver | grep -o "\-\-service\-account\-key\-file=.*" |cut -d ' ' -f1|cut -d '=' -f2);echo $SAKF; if [[ ! -z $SAKF && -e $SAKF ]]; then echo "[ Passed ] Public key for ServiceAccounts found $SAKF. OK."; else echo "[ Failed ] Public key for ServiceAccounts not set or $SAKF not found."; fi;

# etcd TLS (not set by default)
ps -ef | grep kube-apiserver | grep -e "\-\-etcd\-certfile" -e "\-\-etcd\-keyfile";ECF=$(ps -ef | grep kube-apiserver | grep -o "\-\-etcd-certfile=.*" |cut -d ' ' -f1|cut -d '=' -f2);EKF=$(ps -ef | grep kube-apiserver | grep -o "\-\-etcd-\keyfile=.*" |cut -d ' ' -f1|cut -d '=' -f2);if [[ ! -z $ECF && -e $ECF ]]; then echo "[ Passed ] $ECF OK";else echo "[ Failed ] etcd certfile not set or $ECF not found."; fi; if [[ ! -z $EKF && -e $EKF ]]; then echo "[ Passed ] $EKF OK"; else echo "[ Failed ] etcd keyfile not set or $EKF not found.";fi;

# TLS between etcd and apiserver (not set by default)
ps -ef | grep kube-apiserver | grep -e "\-\-etcd\-cafile";ECF=$(ps -ef | grep kube-apiserver | grep -o "\-\-etcd-cafile=.*" |cut -d ' ' -f1|cut -d '=' -f2);if [[ ! -z $ECF && -e $ECF ]]; then echo "[ Passed ] $ECF OK";else echo "[ Failed ] etcd cafile not set or $ECF not found."; fi; 

# etcd over TLS (not set by default)
ps -ef | grep etcd | grep -e "\-\-cert\-file" -e "\-\-key\-file";CF=$(ps -ef | grep etcd | grep -o "\-\-cert\-file=.*" |cut -d ' ' -f1|cut -d '=' -f2);KF=$(ps -ef | grep etcd | grep -o "\-\-key-\file=.*" |cut -d ' ' -f1|cut -d '=' -f2);echo $CF;echo $KF;if [[ ! -z $CF && -e $CF ]]; then echo "[ Passed ] $CF OK";else echo "[ Failed ] etcd cert file not set or $CF not found."; fi; if [[ ! -z $KF && -e $KF ]]; then echo "[ Passed ] $KF OK";else echo "[ Failed ] etcd key file not set or $KF not found."; fi;

# do not allow self-signed certs etcd (allowed by default)
ps -ef | grep etcd | grep -e "\-\-auto\-tls";AT=$(ps -ef | grep etcd | grep -o "\-\-auto\-tls=.*" |cut -d ' ' -f1|cut -d '=' -f2);echo $AT;if [[ "$AT" == "true" ]]; then  echo "[ Failed ] Self-Signed cert allowed for etcd"; else echo "[ Passed ] Self-Signed cert not allowed for etcd. OK."; fi; 

# client auth on etcd (unauthenticated allowed by default)
ps -ef | grep etcd | grep -e "\-\-client\-cert\-auth";CCA=$(ps -ef | grep etcd | grep -o "\-\-client\-cert\-auth=.*" |cut -d ' ' -f1|cut -d '=' -f2);echo $CCA;if [[ "$CCA" != "true" ]]; then  echo "[ Failed ] ClientCertAuth for etcd disabled"; else echo "[ Passed ] ClientCertAuth for etcd set. OK."; fi; 

# etcd TLS encryption for peer connections, for etcd cluster only)
# ps -ef | grep etcd
# Verify that the --peer-cert-file and --peer-key-file set or edit /etc/kubernetes/manifests/etcd.yaml

# etcd peer authentication, for etcd cluster only (false by default)
# --peer-client-cert-auth argument is set to true.
# or edit /etc/kubernetes/manifests/etcd.yaml

# disable self-signed for etcd peer authentication, for etcd cluster only (false by default)
# --peer-auto-tls argument is NOT set to true.
# or edit /etc/kubernetes/manifests/etcd.yaml


# apiserver TLS (not set by default)
ps -ef | grep kube-apiserver | grep -e "\-\-tls\-cert\-file" -e "\-\-tls\-private\-key\-file";TCF=$(ps -ef | grep kube-apiserver | grep -o "\-\-tls\-cert\-file=.*" |cut -d ' ' -f1|cut -d '=' -f2);TPKF=$(ps -ef | grep kube-apiserver | grep -o "\-\-tls\-private\-key\-file=.*" |cut -d ' ' -f1|cut -d '=' -f2);if [[ ! -z $TCF && -e $TCF ]]; then echo "[ Passed ] $TCF OK";else echo "[ Failed ] tls cert file not set or $TCF not found."; fi; if [[ ! -z $TPKF && -e $TPKF ]]; then echo "[ Passed ] $TPKF OK"; else echo "[ Failed ] tls private key file not set or $TPKF not found.";fi;

# apiserver TLS for client (not set by default)
ps -ef | grep kube-apiserver | grep -e "\-\-client\-ca\-file";CCF=$(ps -ef | grep kube-apiserver | grep -o "\-\-client\-ca\-file=.*" |cut -d ' ' -f1|cut -d '=' -f2);if [[ ! -z $CCF && -e $CCF ]]; then echo "[ Passed ] $CCF OK";else echo "[ Failed ] client ca file not set or $CCF not found."; fi;

# individual service account credentials for each controller (false by default)
ps -ef | grep kube-controller-manager | grep -o "\-\-use\-service\-account\-credentials";USAC=$(ps -ef | grep kube-controller-manager | grep -o "\-\-use\-service\-account\-credentials=.*" | cut -d ' ' -f1|cut -d '=' -f2);echo $USAC;if [[ "$USAC" != "true" ]]; then  echo "[ Failed ] Individual ServiceAccount credentials unset."; else echo "[ Passed ] Individual ServiceAccount credentials for each Controller. OK."; fi; 

# kubelet server certificate rotation on controller-manager
ps -ef | grep kube-controller-manager | grep -o "\-\-feature\-gates";RKSC=$(ps -ef | grep kube-controller-manager | grep -o "\-\-feature\-gates=.*" | cut -d ' ' -f1|cut -d '=' -f2 | cut -d '=' -f2);echo $RKSC;if [[ "$RKSC" != "true" ]]; then  echo "[ Failed ] RotateKubeletServerCertificate has not been disabled by default."; else echo "[ Passed ] RotateKubeletServerCertificate for kubelet set. OK."; fi; 



## ------------
## Specific values
## ------------
# Do not always authorize all requests
ps -ef | grep kube-apiserver | grep -o "\-\-authorization\-mode";AMODE=$(ps -ef | grep kube-apiserver | grep -o "\-\-authorization\-mode=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $AMODE;if [[ "$AMODE" == "AlwaysAllow" ]]; then echo "[ Failed ] AlwaysAllow found."; else echo "[ Passed ] AlwaysAllow is disabled. OK"; fi; 

# Restrict kubelet nodes to reading only objects associated with them. (not set by default)
# allows kubelets to read Secret, ConfigMap, PersistentVolume, and PersistentVolumeClaim objects associated with their nodes.
ps -ef | grep kube-apiserver | grep -o "\-\-authorization\-mode";AMODE=$(ps -ef | grep kube-apiserver | grep -o "\-\-authorization\-mode=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $AMODE | grep Node 

# Turn on Role Based Access Control. (not set by default)
ps -ef | grep kube-apiserver | grep "\-\-authorization\-mode";AMODE=$(ps -ef | grep kube-apiserver | grep -o "\-\-authorization\-mode=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $AMODE | grep RBAC

# Do not bind to insecure port (by default set 8080)
ps -ef | grep kube-apiserver | grep -o "\-\-insecure\-port";INP=$(ps -ef | grep kube-apiserver | grep -o "\-\-insecure\-port=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $INP; if [[ ! -z $INP && "$INP" != "0" ]]; then echo "[ Failed ] Insecure Port not set or 0"; else echo "[ Passed ]  Insecure Port not used or set to 0"; fi;

# Do not disable the secure port (by default set to 6443)
# if disabled - no https traffic is served and all traffic is served unencrypted.
# Require API Server up with the right TLS certificates.
ps -ef | grep kube-apiserver | grep -o "\-\-secure\-port";SCP=$(ps -ef | grep kube-apiserver | grep -o "\-\-secure\-port=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $SCP; if [[ ! -z $SCP && $SCP -gt 1 && $SCP -lt 65536 ]]; then echo "[ Passed ] Secure Port $SCP. OK."; else echo "[ Failed ] Secure Port not set or 0"; fi;

# --audit-log-maxage argument is set to 30 or as appropriate (not enabled by default)
# Retain the logs for at least 30 days or as appropriate
ps -ef | grep kube-apiserver | grep -o "\-\-audit\-logs\-maxage";ALM=$(ps -ef | grep kube-apiserver | grep -o "\-\-audit\-logs\-maxage=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $ALM; if [[ ! -z $ALM && $ALM -gt 1 ]]; then echo "[ Passed ] AuditLogsMaxage $ALM. OK."; else echo "[ Failed ] AuditLogMaxage not set. Probably Auditing not enabled."; fi;

# Retain 10 or an appropriate number of old log files (not enabled by default)
ps -ef | grep kube-apiserver | grep -o "\-\-audit\-logs\-maxbackup";ALM=$(ps -ef | grep kube-apiserver | grep -o "\-\-audit\-logs\-maxbackup=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $ALM; if [[ ! -z $ALM && $ALM -gt 1 ]]; then echo "[ Passed ] AuditLogsMaxbackup $ALM. OK."; else echo "[ Failed ] AuditLogMaxbackup not set. Probably Auditing not enabled."; fi;

# Rotate log files on reaching 100 MB or as appropriate (not enabled by default)
ps -ef | grep kube-apiserver | grep -o "\-\-audit\-logs\-maxage";ALM=$(ps -ef | grep kube-apiserver | grep -o "\-\-audit\-logs\-maxsize=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $ALM; if [[ ! -z $ALM && $ALM -gt 1 ]]; then echo "[ Passed ] AuditLogsMaxsize $ALM. OK."; else echo "[ Failed ] AuditLogMaxsize not set. Probably Auditing not enabled."; fi;

# global request timeout for API server requests as appropriate (60s by default)
ps -ef | grep kube-apiserver | grep -o "\-\-request\-timeout";RT=$(ps -ef | grep kube-apiserver | grep -o "\-\-request\-timeout=.*" |cut -d ' ' -f1|cut -d '=' -f2); echo $RT; if [[ ! -z $RT && $RT -gt 1 ]]; then echo "[ Passed ] RequestTimeout $RT. OK."; else echo "[ Failed ] RequestTimeout not set. Default value 60s used."; fi;

# Encrypt etcd key-value store with EncryptionConfig file (not set by default)
# stored Secret is prefixed with k8s:enc:aescbc:v1: which indicates the aescbc provider has encrypted the resulting data (https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
# e.g. EncryptionConfig file CIS-k8s-enc.yaml
ps -ef | grep kube-apiserver | grep -o "\-\-encryption\-provider\-config";EPC=$(ps -ef | grep kube-apiserver | grep -o "\-\-encryption\-provider\-config=.*"|cut -d ' ' -f1|cut -d '=' -f2);echo $EPC;if [[ ! -z $EPC && -e $EPC ]]; then echo "[ Passed ] EncryptionConfig $EPC. OK."; else echo "[ Failed ] EncryptionConfig not set. etcd not use encryption."; fi;

# etcd encryption provider (not set by default)
# identity 	- 	as is
# secretbox - 	XSalsa20 and Poly1305		-	32 bit key
# aesgcm	-	AES-GCM with random nonce 	-	16,24,32 bit key; recommended for use when automated key rotation
# aescbc	-	AES-CBC with PKCS#7 padding	-	32 bit key
# kms 		- envelope encryption 			- 	32 bit key

# ensure apiserver use strong cryptographic ciphers
# --tls-cipher- suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM _SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM _SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM _SHA384
ps -ef | grep kube-apiserver | grep -o "\-\-tls\-cipher\-suites";TCS=$(ps -ef | grep kube-apiserver | grep -o "\-\-tls\-cipher\-suites=.*"|cut -d ' ' -f1|cut -d '=' -f2);echo $TCS;if [[ ! -z $TCS ]]; then echo "[ Passed ] TLSCipherSuites set $TCS. OK."; else echo "[ Failed ] TLSCipherSuites not set. Edit /etc/kubernetes/manifests/kube-apiserver.yaml"; fi;

# Controller Manager GC threshold (12500 terminated pods set by default)
ps -ef | grep kube-controller-manager | grep -o "\-\-terminated\-pod\-gc\-threshold";TPGCT=$(ps -ef | grep kube-controller-manager | grep -o "\-\-terminated\-pod\-gc\-threshold=.*"|cut -d ' ' -f1|cut -d '=' -f2);echo $TPGCT; if [[ ! -z $TPGCT ]]; then echo "[ Passed ] TerminatedPodsGCThreshold set $TPGCT. OK."; else echo "[ Failed ] TerminatedPodsGCThreshold default (12500) used."; fi;

# service account private key file for service accounts on the controller manager (not set by default)
ps -ef | grep kube-controller-manager | grep -o "\-\-service\-account\-private\-key\-file";SAPKF=$(ps -ef | grep kube-controller-manager | grep -o "\-\-service\-account\-private\-key\-file=.*" | cut -d ' ' -f1|cut -d '=' -f2);echo $SAPKF;if [[ -z $SAPKF || ! -e $SAPKF ]]; then  echo "[ Failed ] Individual ServiceAccount privkey unset or $SAPKF not found."; else echo "[ Passed ] Individual ServiceAccount privkey used $SAPKF. OK."; fi; 

# Allow pods to verify the API server's serving certificate before establishing connections (not set by default)
ps -ef | grep kube-controller-manager | grep -o "\-\-root\-ca\-file";RKF=$(ps -ef | grep kube-controller-manager | grep -o "\-\-root\-ca\-file=.*" | cut -d ' ' -f1|cut -d '=' -f2);echo $RKF;if [[ -z $RKF || ! -e $RKF ]]; then  echo "[ Failed ] root ca unset or $RKF not found."; else echo "[ Passed ] root ca used $RKF. OK."; fi; 

# Do not bind the Controller Manager service to non-loopback insecure addresses
#  port 10252/TCP by default (0.0.0.0 used by default)
ps -ef | grep kube-controller-manager | grep -o "\-\-bind\-address";BA=$(ps -ef | grep kube-controller-manager | grep -o "\-\-bind\-address=.*" | cut -d ' ' -f1|cut -d '=' -f2);echo $BA;if [[ "$BA" != "127.0.0.1" ]]; then  echo "[ Failed ] Controller Manager service Bind Address $BA not eq 127.0.0.1."; else echo "[ Passed ] Controller Manager service Bind Address $BA. OK."; fi; 

# Do not bind the scheduler service to non-loopback insecure addresses.
# port 10251/TCP by default (0.0.0.0 used by default)
ps -ef | grep kube-scheduler | grep -o "\-\-bind\-address=.*";BA=$(ps -ef | grep kube-scheduler | grep -o "\-\-bind\-address=.*" | cut -d ' ' -f1|cut -d '=' -f2);echo $BA;if [[ "$BA" != "127.0.0.1" ]]; then  echo "[ Failed ] Scheduler service Bind Address $BA not eq 127.0.0.1."; else echo "[ Passed ] Scheduler service Bind Address $BA. OK."; fi; 










