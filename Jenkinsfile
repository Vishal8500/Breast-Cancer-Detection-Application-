pipeline {
    agent any

    stages {
        stage('Clone') {
            steps {
                // The checkout step is not needed if you're using Pipeline from SCM
                // Jenkins will automatically clone the repository
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                dir('BACKEND') {
                    sh 'docker build -t flask-app .'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('my-app') {
                    sh 'docker build -t react-app .'
                }
            }
        }

        stage('Stop Previous Containers') {
            steps {
                sh '''
                    docker stop flask-backend || true
                    docker rm flask-backend || true
                    docker stop react-frontend || true
                    docker rm react-frontend || true
                '''
            }
        }

        stage('Run Containers') {
            steps {
                sh 'docker run -d -p 5001:5000 --name flask-backend flask-app'
                sh 'docker run -d -p 8080:80 --name react-frontend react-app'
            }
        }
    }

    post {
        failure {
            sh '''
                docker stop flask-backend || true
                docker rm flask-backend || true
                docker stop react-frontend || true
                docker rm react-frontend || true
            '''
        }
    }
}