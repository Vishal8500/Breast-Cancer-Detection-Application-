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
                    # Stop and remove any existing containers
                    docker ps -q --filter "name=flask-backend" | grep -q . && docker stop flask-backend || true
                    docker ps -aq --filter "name=flask-backend" | grep -q . && docker rm flask-backend || true
                    docker ps -q --filter "name=react-frontend" | grep -q . && docker stop react-frontend || true
                    docker ps -aq --filter "name=react-frontend" | grep -q . && docker rm react-frontend || true
                    
                    # Kill any process using port 5001
                    lsof -ti:5001 | xargs -r kill -9 || true
                    
                    # Wait a moment for ports to be released
                    sleep 5
                    
                    # Start the containers
                    docker run -d -p 5001:5000 --name flask-backend flask-app
                    docker run -d -p 8080:80 --name react-frontend react-app
                '''
            }
        }
    }
    
    post {
        failure {
            sh '''
                # Cleanup on failure
                docker ps -q --filter "name=flask-backend" | grep -q . && docker stop flask-backend || true
                docker ps -q --filter "name=react-frontend" | grep -q . && docker stop react-frontend || true
            '''
        }
    }
}
