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
                // Use multiple individual commands instead of a single batch script with FOR loops
                // This avoids input redirection issues
                bat "docker stop %BACKEND_CONTAINER% 2>nul || echo Backend container not running"
                bat "docker rm %BACKEND_CONTAINER% 2>nul || echo No backend container to remove"
                bat "docker stop %FRONTEND_CONTAINER% 2>nul || echo Frontend container not running"
                bat "docker rm %FRONTEND_CONTAINER% 2>nul || echo No frontend container to remove"

                // Check for processes using the backend port and kill them
                bat "echo Checking for processes using port %BACKEND_PORT%..."
                bat "powershell -Command \"Get-NetTCPConnection -LocalPort %BACKEND_PORT% -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }\" || echo No process using port %BACKEND_PORT%"

                // Check for processes using the frontend port and kill them
                bat "echo Checking for processes using port %FRONTEND_PORT%..."
                bat "powershell -Command \"Get-NetTCPConnection -LocalPort %FRONTEND_PORT% -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }\" || echo No process using port %FRONTEND_PORT%"

                // Wait for ports to be released
                bat "echo Waiting for ports to be released..."
                bat "timeout /t 5"

                // Verify ports are free
                bat "echo Verifying ports are free..."
                bat "powershell -Command \"if ((Get-NetTCPConnection -LocalPort %BACKEND_PORT% -ErrorAction SilentlyContinue).Count -gt 0) { Write-Error 'Port %BACKEND_PORT% is still in use!' -ErrorAction Stop } else { Write-Host 'Port %BACKEND_PORT% is free' }\""
                bat "powershell -Command \"if ((Get-NetTCPConnection -LocalPort %FRONTEND_PORT% -ErrorAction SilentlyContinue).Count -gt 0) { Write-Error 'Port %FRONTEND_PORT% is still in use!' -ErrorAction Stop } else { Write-Host 'Port %FRONTEND_PORT% is free' }\""
            }
        }

        stage('Deploy Containers') {
            steps {
                // Start the backend container
                bat "echo Starting backend container..."
                bat "docker run -d -p %BACKEND_PORT%:5000 --name %BACKEND_CONTAINER% %BACKEND_IMAGE%"

                // Start the frontend container
                bat "echo Starting frontend container..."
                bat "docker run -d -p %FRONTEND_PORT%:80 --name %FRONTEND_CONTAINER% %FRONTEND_IMAGE%"

                // Verify containers are running
                bat "echo Checking container status..."
                bat "docker ps"
            }
        }

        stage('Verify Deployment') {
            steps {
                // Wait for services to start
                bat "timeout /t 10"

                // Check if backend is responding
                bat "echo Checking backend health..."
                bat "curl -s -o nul -w \"%%{http_code}\" http://localhost:%BACKEND_PORT% || echo Backend health check failed"

                // Check if frontend is responding
                bat "echo Checking frontend health..."
                bat "curl -s -o nul -w \"%%{http_code}\" http://localhost:%FRONTEND_PORT% || echo Frontend health check failed"
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully!"
        }
        failure {
            // Clean up on failure
            bat "echo Cleaning up on failure..."
            bat "docker stop %BACKEND_CONTAINER% 2>nul || echo Backend container not running"
            bat "docker stop %FRONTEND_CONTAINER% 2>nul || echo Frontend container not running"

            echo "Deployment failed. Containers have been stopped."
        }
        always {
            // Always display container status at the end
            bat 'docker ps -a'
        }
    }
}
