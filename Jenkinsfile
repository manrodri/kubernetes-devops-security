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
      stage("Docker build and push") {
        steps {
         
            sh 'docker build -t manrodri/numeric-app:""$GIT_COMMIT"" .'
            sh 'docker push manrodri/numeric-app:""$GIT_COMMIT""'
          
        }
      }
    }
}