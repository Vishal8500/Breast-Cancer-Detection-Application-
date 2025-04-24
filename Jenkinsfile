pipeline {
    agent any

    environment {
        // Define container names as variables for consistency
        BACKEND_CONTAINER = 'flask-backend'
        FRONTEND_CONTAINER = 'react-frontend'
        // Define image names
        BACKEND_IMAGE = 'flask-app'
        FRONTEND_IMAGE = 'react-app'
        // Define ports
        BACKEND_PORT = '5002'
        FRONTEND_PORT = '8080'
    }

    stages {
        stage('Checkout') {
            steps {
                // Use checkout scm instead of git to use the repository configured in Jenkins
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                dir('BACKEND') {
                    bat 'docker build -t %BACKEND_IMAGE% .'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('my-app') {
                    bat 'docker build -t %FRONTEND_IMAGE% .'
                }
            }
        }

        stage('Clean Up Existing Containers') {
            steps {
                // Windows-compatible commands for stopping and removing containers
                bat '''
                    @echo off

                    REM Stop and remove backend container if it exists
                    FOR /F "tokens=*" %%i IN ('docker ps -q --filter "name=%BACKEND_CONTAINER%"') DO (
                        echo Stopping existing backend container...
                        docker stop %%i
                    )
                    FOR /F "tokens=*" %%i IN ('docker ps -a -q --filter "name=%BACKEND_CONTAINER%"') DO (
                        echo Removing existing backend container...
                        docker rm %%i
                    )

                    REM Stop and remove frontend container if it exists
                    FOR /F "tokens=*" %%i IN ('docker ps -q --filter "name=%FRONTEND_CONTAINER%"') DO (
                        echo Stopping existing frontend container...
                        docker stop %%i
                    )
                    FOR /F "tokens=*" %%i IN ('docker ps -a -q --filter "name=%FRONTEND_CONTAINER%"') DO (
                        echo Removing existing frontend container...
                        docker rm %%i
                    )

                    REM Check if ports are in use and kill processes (Windows-compatible)
                    FOR /F "tokens=5" %%p IN ('netstat -ano ^| findstr :%BACKEND_PORT% ^| findstr LISTENING') DO (
                        echo Killing process using port %BACKEND_PORT%: %%p
                        taskkill /F /PID %%p
                    )

                    REM Wait for ports to be released
                    timeout /t 5
                '''
            }
        }

        stage('Deploy Containers') {
            steps {
                bat '''
                    @echo off

                    REM Start the backend container
                    echo Starting backend container...
                    docker run -d -p %BACKEND_PORT%:5000 --name %BACKEND_CONTAINER% %BACKEND_IMAGE%

                    REM Start the frontend container
                    echo Starting frontend container...
                    docker run -d -p %FRONTEND_PORT%:80 --name %FRONTEND_CONTAINER% %FRONTEND_IMAGE%

                    REM Verify containers are running
                    echo Checking container status...
                    docker ps
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                bat '''
                    @echo off

                    REM Wait for services to start
                    timeout /t 10

                    REM Check if backend is responding
                    echo Checking backend health...
                    curl -s -o nul -w "%%{http_code}" http://localhost:%BACKEND_PORT% || echo Backend health check failed

                    REM Check if frontend is responding
                    echo Checking frontend health...
                    curl -s -o nul -w "%%{http_code}" http://localhost:%FRONTEND_PORT% || echo Frontend health check failed
                '''
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully!"
        }
        failure {
            // Clean up on failure
            bat '''
                @echo off

                echo Cleaning up on failure...

                REM Stop and remove containers if they exist
                FOR /F "tokens=*" %%i IN ('docker ps -q --filter "name=%BACKEND_CONTAINER%"') DO (
                    docker stop %%i
                )
                FOR /F "tokens=*" %%i IN ('docker ps -q --filter "name=%FRONTEND_CONTAINER%"') DO (
                    docker stop %%i
                )
            '''

            echo "Deployment failed. Containers have been stopped."
        }
        always {
            // Always display container status at the end
            bat 'docker ps -a'
        }
    }
}
