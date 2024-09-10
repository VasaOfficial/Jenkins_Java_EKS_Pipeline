# Jenkins_Java_EKS_Pipeline

## CI/CD Pipeline diagram

![Screenshot_4](https://github.com/user-attachments/assets/ea395397-1313-4c93-92a9-00990b91e981)


## Provisioning Infrastructure with Terraform

run this commands:
```
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```
make an key pair on aws and put it in the tfvars

Bonus use kubeaudit for scanning the kubernetes yml file for security reasons

SSH into sonarqube vm and run these commands

```
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```

get the public ip address of sonarqube paste it in url and add :9000 to access it
sonarqube default pass and user is admin, login

To access jenkins paste public ip address and add :8080 at the end of the url

install there jenkins plugins:
<br />
Eclipse Temurin installer
<br />
Config File Provider
<br />
Pipeline Maven Integration
<br />
Maven Integration
<br />
SonarQube Scanner
<br />
Kubernetes
<br />
Kubernetes CLI
<br />
Kubernetes Client Api
<br />
Kubernetes Credentials
<br />
Docker and Docker Pipeline if available

Now configure the plugins:
for jdk add name jdk17 check the install automatically, add installer (Install form adoptium.net) and select version
17.0.9+9

for sonarqube scanner add name sonar-scanner and select the latest version

for maven add name maven3 and select the latest version

for docker add name docker check the install automatically, add installer (download from docker.com) and for version add latest

Now make a pipeline:
select option to discard old builds and to keep max 2 builds

Now configure sonarqube server:
Add a sonarqube token to the jenkins credentials
Now in jenkins system, add sonarqube server, add name sonar, add server url and add soran token at the end

Now configure docker:
add docker credentials, add id docker-cred

Now access and configure k8s cluster:
create svc.yaml file:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: webapps
```

then run

```
kubectl create ns webapps
kubectl apply -f svc.yaml
```

create role.yaml file:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: webapps
rules:
  - apiGroups:
      - ""
      - apps
      - autoscaling
      - batch
      - extensions
      - policy
      - rbac.authorization.k8s.io
    resources:
      - pods
      - secrets
      - componentstatuses
      - configmaps
      - daemonsets
      - deployments
      - events
      - endpoints
      - horizontalpodautoscalers
      - ingress
      - jobs
      - limitranges
      - namespaces
      - nodes
      - pods
      - persistentvolumes
      - persistentvolumeclaims
      - resourcequotas
      - replicasets
      - replicationcontrollers
      - serviceaccounts
      - services
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

then run:

```
kubectl apply -f role.yaml
```

create bind.yaml:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: webapps
rules:
  - apiGroups:
      - ""
      - apps
      - autoscaling
      - batch
      - extensions
      - policy
      - rbac.authorization.k8s.io
    resources:
      - pods
      - secrets
      - componentstatuses
      - configmaps
      - daemonsets
      - deployments
      - events
      - endpoints
      - horizontalpodautoscalers
      - ingress
      - jobs
      - limitranges
      - namespaces
      - nodes
      - pods
      - persistentvolumes
      - persistentvolumeclaims
      - resourcequotas
      - replicasets
      - replicationcontrollers
      - serviceaccounts
      - services
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

then run:

```
kubectl apply -f bind.yaml
kubectl describe secret mysecretname -n webapps
```

copy the token from the terminal, and then add it to the jenkins credentials making sure to select secret text, add the token and add k8-cred as a ID

create sec.yaml:

```yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: mysecretname
  annotations:
    kubernetes.io/service-account.name: jenkins
```

then run:

```
kubectl apply -f sec.yaml -n webapps
```

Monitoring configuration

```
sudo apt update
wget https://github.com/prometheus/prometheus/releases/download/v2.54.1/prometheus-2.54.1.linux-amd64.tar.gz
tar -xvf prometheus-2.51.0-rc.0.linux-amd64.tar.gz
rm -rf prometheus-2.51.0-rc.0.linux-amd64.tar.gz
cd prometheus-2.51.0-rc.0.linux-amd64/
./prometheus &
cd ..
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.2.0_amd64.deb
sudo dpkg -i grafana-enterprise_11.2.0_amd64.deb
sudo /bin/systemctl start grafana-server
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz
tar -xvf blackbox_exporter-0.25.0.linux-amd64.tar.gz
rm -rf blackbox_exporter-0.25.0.linux-amd64.tar.gz
cd blackbox_exporter-0.25.0.linux-amd64/
./blackbox_exporter &
cd ..
```

Grafana default pass and user is admin

Setup blackbox exporter

```
cd prometheus-2.51.0-rc.0.linux-amd64/
vi prometheus.yml
```

Paste this in prometheus.yml

```yaml
- job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]  # Look for a HTTP 200 response.
    static_configs:
      - targets:
        - http://prometheus.io    # Target to probe with http.
        - http://example.com:8080 # HERE GOES THE ULR OF THE APPLICATION
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 'here goes the ip of your blackbox':9115  # The blackbox exporter's real hostname:port.
```

After that is done run this:

```
pgrep prometheus
kill {number gotten from the last command}
./prometheus &
```

Next add prometheus as data source in grafana, also add dashboard with an id of 7587

add pipeline script:

```
pipeline {
agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        SCANNER_HOME= tool 'sonar-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
               git branch: 'main', credentialsId: 'git-cred', url: 'your github url here'
            }
        }

        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }

        stage('Test') {
            steps {
                sh "mvn test"
            }
        }

        stage('File System Scan') {
            steps {
                sh "trivy fs --format table -o trivy-fs-report.html ."
            }
        }

        stage('SonarQube Analsyis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=BoardGame -Dsonar.projectKey=BoardGame \
                            -Dsonar.java.binaries=. '''
                }
            }
        }

        stage('Build') {
            steps {
               sh "mvn package"
            }
        }

        stage('Build & Tag Docker Image') {
            steps {
               script {
                   withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                            sh "docker build -t 'here add your docker tag' ."
                    }
               }
            }
        }

        stage('Docker Image Scan') {
            steps {
                sh "trivy image --format table -o trivy-image-report.html 'here add your docker tag' "
            }
        }

        stage('Push Docker Image') {
            steps {
               script {
                   withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                            sh "docker push 'here add your docker tag'"
                    }
               }
            }
        }
        stage('Deploy To Kubernetes') {
            steps {
               withKubeConfig(caCertificate: '', clusterName: 'here add cluster name', contextName: '', credentialsId: 'k8-cred', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'here add your k8s server endpoint') {
                        sh "kubectl apply -f deployment-service.yaml"
                }
            }
        }

        stage('Verify the Deployment') {
            steps {
               withKubeConfig(caCertificate: '', clusterName: 'here add cluster name', contextName: '', credentialsId: 'k8-cred', namespace: 'webapps', restrictKubeConfigAccess: false, serverUrl: 'here add your k8s server endpoint') {
                        sh "kubectl get pods -n webapps"
                        sh "kubectl get svc -n webapps"
                }
            }
        }
    }
    post {
    always {
        script {
            def jobName = env.JOB_NAME
            def buildNumber = env.BUILD_NUMBER
            def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
            def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

            def body = """
                <html>
                <body>
                <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                <h2>${jobName} - Build ${buildNumber}</h2>
                <div style="background-color: ${bannerColor}; padding: 10px;">
                <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                </div>
                <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                </div>
                </body>
                </html>
            """
        }
    }

  }
}

```
