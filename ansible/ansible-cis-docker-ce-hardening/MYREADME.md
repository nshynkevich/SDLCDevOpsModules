# Ansible tests for docker

Tested on docker **20.10.21**. 
Copy of official https://github.com/mitre/ansible-cis-docker-ce-hardening.git, adapted for new docker version


# Run

```cd ansible-cis-docker-ce-hardening```
```sudo ansible-playbook tasks/local-main.yml --extra-vars "@defaults/local-main-vars.yml"```


