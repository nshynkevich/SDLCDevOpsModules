# Module 1

## CI/CD pipeline

- Build a barebone DevOps pipeline
- Create infrastructure - VM1 and K8s cluster (two node)
- Set up Jenkins
- Configure pipeline

#### Requirements

Toolset:
- Git
- Jenkis
- Docker
- K8s

1. The application was pulled from GitHub
2. A container image with the application was created 
3. The application was deployed into the K8s cluster 
4. Create C4-model (context, container) diagram

# Module 2

## SAST/DAST

### Level - medium:

#### Requirements:

Toolset: 
- SAST
- code-level SCA
- DAST
    
1. SAST was implemented into the pipeline 
2. Code-level SCA is implemented into the pipeline 
3. DAST was implemented into the pipeline 
4. Create a C4-model (context, container) diagram of the environment (not the app)

### Level - Security ninja:

#### Requirements:

1. SAST case: setup custom quality profile and quality gate, ensure that pipeline build failed on your conditions 
2. SCA case: setup code-level SCA quality gate 
3. DAST case: setup a "test" environment with another one-node k8s cluster. Integrate DAST and setup a quality gate to allow "production" deployment only on your conditions 
4. Create a C4-model (context, container) diagram of the environment (not the app)
5. Integrate static and dynamic application security testing into the pipeline. Get the testing results and analyze them.


# Module 3

## Add DockerImage scanning into the pipeline

Perform Docker engine hardening

### Requirements

Toolset: 
- Ansible

1. DockerImage scanning was implemented into the pipeline 
2. Docker engine hardening was implemented based on CIS Benchmark 
3. Create a C4-model (context, container) diagram of the environment (not the app)


# Module 4

## Hardening

1. Add k8s YAML files scanning into the pipeline 
2. Add k8s engine hardening into the pipeline 
3. Deploy K8s runtime security tool 
4. Configure OPA Kubernetes Admission Control


### Requirements

Toolset: 
- Ansible
- Aqua Security
- Falco

1. Deploy Falco via Helm 
2. Kubernetes engine hardening was implemented based on CIS Benchmark 
3. Create a C4-model (context, container) diagram of the environment (not the app)

# Module 5

## Cloud Security

1. Deploy infrastructure by IaC (same as on-premise but using cloud-native services as much as possible) 
2. Deploy infrastructure in Cloud

### Requirements

1. Implement Network Security Groups for VMs 
2. Install Azure antimalware agents where possible  
3. Replace VM-based Kubernetes with AKS 
4. Implement AKS hardening according to the CIS benchmark.  
5. Move previous security configurations (tools) to AKS where possible  
6. Update a C4-model (context, container) diagram of the environment (not the app)
7. Scan IaC (* into the pipeline)

Toolset: 
- Checkov 

*(optional task) 

_Please do not keep AKS working for a prolonged period. This helps to avoid high costs for service usage._

# Module 6

## Analyze results & lessons learned

1. Goals of this mentoring  
2. Practical task diagram  
3. Practical task showcase:
   1. Vulnerable app    
   2. Integrated components    
   3. Quality gates     
   4. Most notable findings 
4. Results 
5. Q&A (both sides) 




