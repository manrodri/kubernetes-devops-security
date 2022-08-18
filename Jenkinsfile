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
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
        }

       stage('Mutation Tests - PIT') {
          steps {
            sh "mvn org.pitest:pitest-maven:mutationCoverage"
          }
          post {
            always {
              pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
            }
          }
       }

       stage("SonarQ analysis")  {
        steps {
          withSonarQubeEnv('sonarq'){
          sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://jenkins.manrodri.com:9000 -Dsonar.login=f9e10636759f89c4c980dace0f3c921f6eaf2d3f"
          }
          timeout(time: 2, unit: 'MINUTES'){
            script {
              waitForQualityGate abortPipeline: true
            }
          }
        }
       }

      stage("Docker build and push") {
        steps {
          withDockerRegistry([credentialsId: "docker-hub", url: ""]){
            sh 'docker build -t manrodri/numeric-app:""$GIT_COMMIT"" .'
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
}

