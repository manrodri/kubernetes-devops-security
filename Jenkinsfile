pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "manrodri/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://jenkins.manrodri.com/"
    applicationURI = "/increment/99"
  }

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'
            }
        }
      stage('Unit Test') {
            steps {
              sh "mvn test"
            }
            
        }

       stage('Mutation Tests - PIT') {
          steps {
            sh "mvn org.pitest:pitest-maven:mutationCoverage"
          }
          
       }

       stage("SonarQ analysis")  {
        steps {
          withSonarQubeEnv('sonarq'){
          sh "mvn sonar:sonar \
           -Dsonar.projectKey=numeric-application \
           -Dsonar.host.url=http://jenkins.manrodri.com:9000"
          }
          timeout(time: 2, unit: 'MINUTES'){
            script {
              waitForQualityGate abortPipeline: true
            }
          }
        }
       }

      stage("Vulnerability scan - Docker image"){

        steps {
          parallel(
            "Dependency scan" : {
              sh "mvn dependency-check:check"
            },
            "Trivy scan": {
                sh "bash trivi-docker-image-scan.sh"
            },
            "OPA Conftest": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
          }
          )
        }
      }

      stage("Docker build and push") {
        steps {
          withDockerRegistry([credentialsId: "docker-hub", url: ""]){
            sh 'sudo docker build -t manrodri/numeric-app:""$GIT_COMMIT"" .'
            sh 'docker push manrodri/numeric-app:""$GIT_COMMIT""'
          }
        }
      }

      stage('Vulnerability Scan - Kubernetes') {
        steps {
          parallel(
            "Opa Scan": {
              sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
            },
            "Kubesec Scan": {
              sh 'bash kubesec-scan.sh'
            },
            "Trivy Scan": {
              sh "bash trivy-k8s-scan.sh"
            }
          )
          
        }
      }

      stage('Kubernetes Deployment - DEV'){
        steps {
          parallel(
                    "Deployment": {
                      withKubeConfig([credentialsId: 'k8s-config']){
                        sh "bash k8s-deployment.sh"
                      }
                    },
                    "Rollout status": {
                      withKubeConfig([credentialsId: 'k8s-config']){
                        sh "bash k8s-deployment-rollout-status.sh"
                      }
                    }
                  )
        }
      }
      stage("Integration tests"){
      steps{
        script {
          try {
            withKubeConfig([credentialsId: 'k8s-config']){
                        sh "bash integration-tests.sh"
                      }
          } catch(e){
              withKubeConfig([credentialsId: 'k8s-config']){
                        sh "kubectl -n default rollout undo deploy ${deploymentName}"
                      }
          }
          throw e
        }
      }
    }

      stage("OWASP ZAP analysis"){
        steps {
          withKubeConfig([credentialsId: 'k8s-config']){
            sh 'bash zap.sh'
          }
        }
      }

    }

    
    post {
      always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
                pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
      }
      // success {

      // }
      // failure {

      // }
    }
}
