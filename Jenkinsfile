pipeline {
    agent any

    environment {
        // Define container name
        APP_CONTAINER = 'breast-cancer-app'
        // Define image name
        APP_IMAGE = 'breast-cancer-detection-app'
        // Define default port
        DEFAULT_PORT = '5000'
        // Define port variable to be dynamically assigned
        APP_PORT = ''
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                script {
                    try {
                        bat "docker build -t ${APP_IMAGE} ."
                    } catch (Exception e) {
                        error "Build failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Clean Up Environment') {
            steps {
                script {
                    try {
                        bat """
                            echo Cleaning up existing container...
                            docker stop ${APP_CONTAINER} 2>nul || echo No container to stop
                            docker rm ${APP_CONTAINER} 2>nul || echo No container to remove

                            echo Releasing port ${DEFAULT_PORT}...
                            powershell -Command "
                                Get-NetTCPConnection -LocalPort ${DEFAULT_PORT} -ErrorAction SilentlyContinue |
                                ForEach-Object {
                                    try {
                                        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
                                        Write-Host 'Stopped process using port ${DEFAULT_PORT}'
                                    } catch {
                                        Write-Host 'No process using port ${DEFAULT_PORT}'
                                    }
                                }
                            "

                            echo Waiting for port to release...
                            ping -n 6 127.0.0.1 >nul
                        """
                    } catch (Exception e) {
                        echo "Warning during cleanup: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Assign Available Port') {
            steps {
                script {
                    // Dynamically check for available ports in a range
                    try {
                        echo "Checking for available port..."
                        def availablePort = sh(script: """
                            for /l %%x in (5000, 1, 5090) do (
                                netstat -an | findstr /c:"%%x" >nul
                                if %errorlevel% neq 0 (
                                    echo %%x
                                    exit /b
                                )
                            )
                            echo No available ports found
                        """, returnStdout: true).trim()
                        
                        if (availablePort) {
                            echo "Assigning port ${availablePort} for the application."
                            APP_PORT = availablePort
                        } else {
                            error "No available ports found in the range 5000-5090"
                        }
                    } catch (Exception e) {
                        error "Failed to assign an available port: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Deploy Container') {
            steps {
                script {
                    try {
                        echo "Starting application container on port ${APP_PORT}..."
                        bat """
                            docker run -d --name ${APP_CONTAINER} -p ${APP_PORT}:5000 ${APP_IMAGE}
                            ping -n 11 127.0.0.1 >nul
                            docker inspect -f "{{.State.Running}}" ${APP_CONTAINER} | findstr true || exit 1
                        """
                    } catch (Exception e) {
                        error "Deployment failed: ${e.getMessage()}"
                    }
                }
            }
        }

        stage('Verify Service') {
            steps {
                script {
                    try {
                        echo "Verifying application health on port ${APP_PORT}..."
                        bat """
                            for /l %%x in (1, 1, 6) do (
                                curl -s -f http://localhost:${APP_PORT} && exit 0
                                ping -n 6 127.0.0.1 >nul
                            )
                            echo Health check failed!
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
                bat "echo Deployment successful! Service is running."
                bat "docker ps"
            }
        }

        failure {
            script {
                bat """
                    echo Cleaning up resources due to failure...
                    docker stop ${APP_CONTAINER} 2>nul || echo No container to stop
                    docker rm ${APP_CONTAINER} 2>nul || echo No container to remove
                    docker ps -a
                """
            }
        }

        always {
            cleanWs(
                cleanWhenNotBuilt: false,
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true
            )
        }
    }
}
