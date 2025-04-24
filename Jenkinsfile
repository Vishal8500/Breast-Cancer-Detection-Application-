pipeline {
    agent any
    
    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/Vishal8500/Breast-Cancer-Detection-Application.git'
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
        
        stage('Deploy') {
            steps {
                sh '''
                    docker stop flask-backend || true
                    docker rm flask-backend || true
                    docker stop react-frontend || true
                    docker rm react-frontend || true
                    
                    docker run -d -p 5001:5000 --name flask-backend flask-app
                    docker run -d -p 8080:80 --name react-frontend react-app
                '''
            }
        }
    }
}
