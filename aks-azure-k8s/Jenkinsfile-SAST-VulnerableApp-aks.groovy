pipeline {
  environment {
    user = "nshynkevich"
    repo = "devsecops"
    imagetag= "module2_VulnerableApp"
    registryCredential = 'dockerhub'
    dockerImage = ''
  }

  agent any

  stages {

    stage('Checkout Source') {
      steps {
        git url:'https://github.com/nshynkevich/VulnerableApp.git', branch:'master'

        script {
          sh 'sed -i -e "s@127.0.0.1:9090@${VULNERABLE_IP}:${VULNERABLE_PORT}@g" src/main/resources/sitemap.xml'
        }
      }
    }

    stage('SonarQube analysis') {
      steps {
        withSonarQubeEnv(installationName: 'SonarQubeVM1') {
          sh "./gradlew sonarqube \
                  -Dsonar.host.url=${env.SONAR_HOST_URL} \
                  -Dsonar.login=${env.SONAR_AUTH_TOKEN} \
                  -Dsonar.projectKey=${MY_SONAR_TOKEN} \
                  -Dsonar.qualitygate.wait=true \
                  -Dsonar.projectName='vulnapp' \
                  -Dsonar.projectVersion=${BUILD_NUMBER} \
                  -Dsonar.coverage.jacoco.xmlReportPaths=build/reports/jacoco/codeCoverage.xml \
                  -Dsonar.dependencyCheck.xmlReportPath=build/reports/dependency-check-report.xml \
                  -Dsonar.dependencyCheck.htmlReportPath=build/reports/dependency-check-report.html \
                  -Dsonar.dependencyCheck.jsonReportPath=build/reports/dependency-check-report.json \
                  -Dsonar.dependencyCheck.summarize=true"
        }
      }
    }

    stage('OWASP Dependency Check analysis') {
      steps {
        script{
          sh "./gradlew dependencyCheckAnalyze"
        }
      }
    }

    stage('Build App with gradle') {
      steps {
        script {
          sh '/opt/gradle/gradle-7.5/bin/gradle bootJar'
        }
      }
    }

    stage('Create app Dockerfile') {
      steps {
        script {
          def vulnapp_dockerfile_content = '''
FROM openjdk:8-alpine

ADD build/libs/VulnerableApp-1.0.0.jar /VulnerableApp-1.0.0.jar
COPY src/main/resources/sitemap.xml /sitemap.xml
WORKDIR /

EXPOSE 9090

CMD java -jar /VulnerableApp-1.0.0.jar

'''
          writeFile file: 'Dockerfile', text: vulnapp_dockerfile_content

        }
      }
    }

    stage("Build image") {
      steps {
        script {
          //myapp = docker.build("user/repo:${env.BUILD_ID}")
          dockerImage = docker.build "${user}/${repo}:${env.imagetag}_${env.BUILD_ID}"
        }
      }
    }

    stage("Scan with trivy") {
      steps {
        sh "trivy image -f table ${user}/${repo}:${env.imagetag}_${env.BUILD_ID}"
        //sh "trivy image -f json -o trivyscan-1owasp-2build-${env.imagetag}_${env.BUILD_ID}.json ${user}/${repo}:${env.imagetag}_${env.BUILD_ID}"
        //recordIssues(tools: [trivy(pattern: 'results.json')])
      }
    }

    /*stage("Scan with trivy (store in .json format)") {
      steps {
        sh "trivy image -f json -o trivyscan-${env.imagetag}_${env.BUILD_ID}.json ${user}/${repo}:${env.imagetag}_${env.BUILD_ID}"
        //recordIssues(tools: [trivy(pattern: 'results.json')])
      }
    }*/

    /*stage("Scan with trivy (store in .json format. Fail if HIGH,CRITICAL found)") {
      steps {
        sh "trivy image -f json -o trivyscan-_no-criticals_-${env.imagetag}_${env.BUILD_ID}.json --no-progress --exit-code 1 --severity HIGH,CRITICAL ${user}/${repo}:${env.imagetag}_${env.BUILD_ID}"
        //recordIssues(tools: [trivy(pattern: 'results.json')])
      }
    }*/

    stage("Push image") {
      steps {
        script {
          docker.withRegistry('', 'dockerhub') {
            dockerImage.push("${env.imagetag}_${env.BUILD_ID}")
            dockerImage.push("${env.imagetag}_latest")
          }
        }
      }
    } 

    stage('Create app .yaml file for k8s') {
      steps {
        script {
          def vulnerableapp_yaml_content = '''
---
apiVersion: v1
kind: Namespace
metadata:
  name: vulnapp

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vulnerableapp
  namespace: vulnapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vulnerableapp
  template:
    metadata:
      name: vulnerableapp-pod
      labels:
        app: vulnerableapp
    spec:
      containers:
      - name: vulnerableapp-container
        image: ''' + "${user}/${repo}:${imagetag}_latest" + '''
        imagePullPolicy: Always
        ports:
        - containerPort: 9090
---
apiVersion: v1
kind: Service
metadata:
  name: vulnerableapp-svc
  namespace: vulnapp
  labels:
    app: vulnerableapp
spec:
  selector:
    app: vulnerableapp
  type: NodePort
  ports:
  - nodePort: 30001
    port: 9090
    targetPort: 9090
'''
          writeFile file: 'vulnerableapp.yaml', text: vulnerableapp_yaml_content
          sh 'ls -l vulnerableapp.yaml'
          sh 'cat vulnerableapp.yaml'

        }
      }
    }

    stage('Deploy App to k8s') {
      steps {
        script {
          kubernetesDeploy(configs: "vulnerableapp.yaml", kubeconfigId: "kubeconfig")
        }
      }
    }
  }
}
