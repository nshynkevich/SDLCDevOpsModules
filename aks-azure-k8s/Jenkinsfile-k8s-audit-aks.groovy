def k8sCredentialsId = 'kubeconfig-secretfile'
def k8sServerUrl = 'https://somelongurllooks-likethis.hcp.northeurope.azmk8s.io:443'

pipeline {  

	environment {
		kubebench_node_job_yaml = "kube-bench_node_job.yaml"
	}

	agent any
	
	stages {
		stage("0. Audit K8S cluster with kube-bench: create jobs for node only (node pool AKS master not managed by users) ") {
			steps {
				script {
				    def kubebench_node_job_yaml_content = '''
---
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench-node
spec:
  template:
    spec:
      hostPID: true
      containers:
        - name: kube-bench
          image: docker.io/aquasec/kube-bench:latest
          command: ["kube-bench", "run", "--targets", "node"]
          volumeMounts:
            - name: var-lib-etcd
              mountPath: /var/lib/etcd
              readOnly: true
            - name: var-lib-kubelet
              mountPath: /var/lib/kubelet
              readOnly: true
            - name: var-lib-kube-scheduler
              mountPath: /var/lib/kube-scheduler
              readOnly: true
            - name: var-lib-kube-controller-manager
              mountPath: /var/lib/kube-controller-manager
              readOnly: true
            - name: etc-systemd
              mountPath: /etc/systemd
              readOnly: true
            - name: lib-systemd
              mountPath: /lib/systemd/
              readOnly: true
            - name: srv-kubernetes
              mountPath: /srv/kubernetes/
              readOnly: true
            - name: etc-kubernetes
              mountPath: /etc/kubernetes
              readOnly: true
              # /usr/local/mount-from-host/bin is mounted to access kubectl / kubelet, for auto-detecting the Kubernetes version.
              # You can omit this mount if you specify --version as part of the command.
            - name: usr-bin
              mountPath: /usr/local/mount-from-host/bin
              readOnly: true
            - name: etc-cni-netd
              mountPath: /etc/cni/net.d/
              readOnly: true
            - name: opt-cni-bin
              mountPath: /opt/cni/bin/
              readOnly: true
      restartPolicy: Never
      volumes:
        - name: var-lib-etcd
          hostPath:
            path: "/var/lib/etcd"
        - name: var-lib-kubelet
          hostPath:
            path: "/var/lib/kubelet"
        - name: var-lib-kube-scheduler
          hostPath:
            path: "/var/lib/kube-scheduler"
        - name: var-lib-kube-controller-manager
          hostPath:
            path: "/var/lib/kube-controller-manager"
        - name: etc-systemd
          hostPath:
            path: "/etc/systemd"
        - name: lib-systemd
          hostPath:
            path: "/lib/systemd"
        - name: srv-kubernetes
          hostPath:
            path: "/srv/kubernetes"
        - name: etc-kubernetes
          hostPath:
            path: "/etc/kubernetes"
        - name: usr-bin
          hostPath:
            path: "/usr/bin"
        - name: etc-cni-netd
          hostPath:
            path: "/etc/cni/net.d/"
        - name: opt-cni-bin
          hostPath:
            path: "/opt/cni/bin/"

'''
                    try {
                        echo "Create k8s kube-bench node job yaml file: ${kubebench_node_job_yaml} .. "
						writeFile(file: kubebench_node_job_yaml, text: kubebench_node_job_yaml_content)
            			sh 'ls -l ' + "${kubebench_node_job_yaml}" + ' ; cat ' + "${kubebench_node_job_yaml}"
            				
					} catch (err) {
						currentBuild.result = 'FAILURE'
						errorMsg = "Build Failure: "+ err.getMessage()
						throw err
					}
					echo "[+] OK .. "
				}
	    	}
		}

		stage("1. Audit with kube-bench: deploy jobs for node in cluster") {
			steps {
				withKubeConfig([credentialsId: "${k8sCredentialsId}",
				    serverUrl: "${k8sServerUrl}"]) {
					sh '''
kubectl apply -f ''' + "${WORKSPACE}/${kubebench_node_job_yaml}" + ''' && echo "Applied from ''' + "${kubebench_node_job_yaml}" + ''' OK";
'''
				}
			}
		}

		stage("2. Audit with kube-bench: get Kube-bench audit logs") {
			steps {
				withKubeConfig([credentialsId: "${k8sCredentialsId}",
				    serverUrl: "${k8sServerUrl}"]) {
					sh '''
kubebench_node_pod=$(kubectl get pods --selector=job-name=kube-bench-node --output=jsonpath='{.items[*].metadata.name}'|head -n 1);

kubectl wait --for=condition=complete --timeout=20m job/kube-bench-node && \
	kubectl logs $kubebench_node_pod > ${WORKSPACE}/kubebench_node_job.log;

if [ -s ${WORKSPACE}/kubebench_node_job.log ]; then
  echo "[+] Found ${WORKSPACE}/kubebench_node_job.log: ";
  echo "----";echo;
  cat ${WORKSPACE}/kubebench_node_job.log;
  echo "----";echo;
else 
  echo "[-] ${WORKSPACE}/kubebench_node_job.log file not exist. Check kube-bench job config."
fi;
'''
    			}
			}
		}

		stage("3. Audit with Checkov: ") {
			steps {
				script {
					withKubeConfig([credentialsId: "${k8sCredentialsId}",
					    serverUrl: "${k8sServerUrl}"]) {
						sh '''
CHECKOV_YAML_URL="https://raw.githubusercontent.com/bridgecrewio/checkov/master/kubernetes/checkov-job.yaml";
CHECKOV_YAML="checkov-job.yaml"; if [ -s $CHECKOV_YAML ]; then rm -f $CHECKOV_YAML ; fi ;
BASE64_PY="aW1wb3J0IHlhbWwKaW1wb3J0IHN5cwoKCmRlZiBoYXNfZGljdF9rZXlzKGQsIGtleXMpOgogICAgaWYgaXNpbnN0YW5jZShrZXlzLCBsaXN0KToKICAgICAgICBmb3IgXyBpbiBrZXlzOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBkID0gZFtfXQogICAgICAgICAgICBleGNlcHQ6CiAgICAgICAgICAgICAgICByZXR1cm4gRmFsc2UKICAgICAgICAgICAgcmV0dXJuIFRydWUKICAgIGVsc2U6CiAgICAgICAgaWYga2V5cyBpbiBkLmtleXMoKToKICAgICAgICAgICAgcmV0dXJuIFRydWUsIGRba2V5c10KICAgICAgICByZXR1cm4gRmFsc2UKCgpkZWYgc2V0X25lc3RlZChkLCBrLCB2KToKICAgIGlmIGxlbihrKSA8PSAxOgogICAgICAgIGRba1swXV0gPSB2CiAgICBlbHNlOgogICAgICAgIG9rID0ga1swXQogICAgICAgIGsgPSBrWzE6XQogICAgICAgIHNldF9uZXN0ZWQoZFtva10sIGssIHYpCgoKZGVmIHJlYWRfYW5kX21vZGlmeV9vbmVfYmxvY2tfb2ZfeWFtbF9kYXRhKGtleSwgZmlsdGVyX2J5LCBuZXdfZGF0YSk6CiAgICBmID0gc3lzLnN0ZGluLnJlYWQoKQogICAgZGF0YSA9IHlhbWwuc2FmZV9sb2FkX2FsbChmKQogICAgZGF0YV9hbGwgPSBbXQogICAgZm9yIGRvYyBpbiBkYXRhOgogICAgICAgIGRvY19kaWN0ID0gZG9jCiAgICAgICAgaWYgaGFzX2RpY3Rfa2V5cyhkb2NfZGljdCwga2V5KToKICAgICAgICAgICAgZG9jXyA9IGRvY19kaWN0CiAgICAgICAgICAgIGZvciBrIGluIGtleToKICAgICAgICAgICAgICAgIGRvY18gPSBkb2NfW2tdCiAgICAgICAgICAgIGlmIGlzaW5zdGFuY2UoZG9jXywgbGlzdCk6CiAgICAgICAgICAgICAgICBkb2NfID0gZG9jX1swXQogICAgICAgICAgICBpZiBmaWx0ZXJfYnlbJ2tleSddIGluIGRvY18ua2V5cygpIGFuZCBkb2NfW2ZpbHRlcl9ieVsna2V5J11dID09IGZpbHRlcl9ieVsndmFsdWUnXToKICAgICAgICAgICAgICAgIGRvY18gPSB7Kipkb2NfLCAqKm5ld19kYXRhfQogICAgICAgICAgICBzZXRfbmVzdGVkKGRvY19kaWN0LCBrZXksIGRvY18pCiAgICAgICAgZGF0YV9hbGwuYXBwZW5kKGRvY19kaWN0KQogICAgcmV0dXJuIHlhbWwuZHVtcF9hbGwoZGF0YV9hbGwpCgoKciA9IHJlYWRfYW5kX21vZGlmeV9vbmVfYmxvY2tfb2ZfeWFtbF9kYXRhKGtleT1bJ3NwZWMnLCAndGVtcGxhdGUnLCAnc3BlYycsICdjb250YWluZXJzJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmaWx0ZXJfYnk9eydrZXknOiAnbmFtZScsICd2YWx1ZSc6ICdjaGVja292J30sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBuZXdfZGF0YT17J3Jlc291cmNlcyc6IHsKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAncmVxdWVzdHMnOiB7J21lbW9yeSc6ICc1MTJNaSd9LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdsaW1pdHMnOiB7J21lbW9yeSc6ICcxMDI0TWknfQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSkKcHJpbnQocikK";
wget -O - $CHECKOV_YAML_URL  2>/dev/null | /usr/bin/python3 -c "import base64;exec(base64.b64decode('$BASE64_PY'))" > $CHECKOV_YAML;

kubectl apply -f $CHECKOV_YAML;

checkov_pod=$(kubectl get pods -n checkov --selector=job-name=checkov --output=jsonpath='{.items[*].metadata.name}' | head -n 1);
kubectl wait --for=condition=complete --timeout=15m job/checkov -n checkov && \
	kubectl logs $checkov_pod -n checkov > ${WORKSPACE}/checkov_job.log;

if [ -s ${WORKSPACE}/checkov_job.log ]; then
  echo "[+] Found ${WORKSPACE}/checkov_job.log: ";
  echo "----";echo;
  cat ${WORKSPACE}/checkov_job.log;
  echo "----";echo;
else 
  echo "[-] ${WORKSPACE}/checkov_job.log file not exist. Check checkov job config ( $CHECKOV_YAML )."
fi;
'''
					}
				}
			}
		}
	}
}