pipeline {
  agent any

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
      stage('Kubernetes Deployment - DEV'){
        steps{
          withKubeConfig([credentialsId: 'k8s-config']) {
            sh "sed -i 's#replace#manrodri/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
            sh "kubectl apply -f k8s_deployment_service.yaml"
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

