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
                checkout scm
            }
        }

        stage('Build Images') {
            parallel {
                stage('Build Backend') {
                    steps {
                        script {
                            dir('BACKEND') {
                                try {
                                    bat 'docker build -t %BACKEND_IMAGE% .'
                                } catch (Exception e) {
                                    error "Backend build failed: ${e.getMessage()}"
                                }
                            }
                        }
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        script {
                            dir('my-app') {
                                try {
                                    bat 'docker build -t %FRONTEND_IMAGE% .'
                                } catch (Exception e) {
                                    error "Frontend build failed: ${e.getMessage()}"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Clean Up Environment') {
            steps {
                script {
                    try {
                        // Stop and remove existing containers
                        bat """
                            docker stop %BACKEND_CONTAINER% %FRONTEND_CONTAINER% 2>nul || echo "No containers to stop"
                            docker rm %BACKEND_CONTAINER% %FRONTEND_CONTAINER% 2>nul || echo "No containers to remove"
                        """

                        // Kill processes using the ports (with error handling)
                        bat """
                            powershell -Command "
                                foreach ($port in @('%BACKEND_PORT%', '%FRONTEND_PORT%')) {
                                    Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
                                    ForEach-Object { 
                                        try {
                                            Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
                                        } catch {
                                            Write-Host "No process using port $port"
                                        }
                                    }
                                }
                            "
                        """

                        // Wait for ports to be released
                        bat "timeout /t 5 /nobreak"
                    } catch (Exception e) {
                        echo "Warning during cleanup: ${e.getMessage()}"
                        // Continue pipeline even if cleanup has warnings
                    }
                }
            }
        }

        stage('Deploy Containers') {
            steps {
                script {
                    try {
                        // Deploy backend with health check
                        bat """
                            docker run -d --name %BACKEND_CONTAINER% -p %BACKEND_PORT%:5000 %BACKEND_IMAGE%
                            timeout /t 10 /nobreak
                            docker inspect -f {{.State.Running}} %BACKEND_CONTAINER% | findstr true || exit 1
                        """

                        // Deploy frontend with health check
                        bat """
                            docker run -d --name %FRONTEND_CONTAINER% -p %FRONTEND_PORT%:80 %FRONTEND_IMAGE%
                            timeout /t 10 /nobreak
                            docker inspect -f {{.State.Running}} %FRONTEND_CONTAINER% | findstr true || exit 1
                        """
                    } catch (Exception e) {
                        error "Deployment failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Verify Services') {
            steps {
                script {
                    try {
                        // More reliable health checks
                        bat """
                            for /l %%x in (1, 1, 6) do (
                                curl -s -f http://localhost:%BACKEND_PORT%/health && exit 0
                                timeout /t 5 /nobreak
                            )
                            exit 1
                        """

                        bat """
                            for /l %%x in (1, 1, 6) do (
                                curl -s -f http://localhost:%FRONTEND_PORT% && exit 0
                                timeout /t 5 /nobreak
                            )
                            exit 1
                        """
                    } catch (Exception e) {
                        error "Service verification failed: ${e.getMessage()}"
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                bat "echo Deployment successful! Services are running."
                bat "docker ps"
            }
        }
        failure {
            script {
                // Cleanup on failure
                bat """
                    echo Cleaning up resources due to failure...
                    docker stop %BACKEND_CONTAINER% %FRONTEND_CONTAINER% 2>nul || echo No containers to stop
                    docker rm %BACKEND_CONTAINER% %FRONTEND_CONTAINER% 2>nul || echo No containers to remove
                    docker ps -a
                """
            }
        }
        always {
            // Workspace cleanup
            cleanWs(
                cleanWhenNotBuilt: false,
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true
            )
        }
    }
}
