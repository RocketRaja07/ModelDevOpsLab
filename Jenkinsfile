pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'your-registry.com'  // Replace with your registry
        APP_NAME = 'devops-demo'
        DOCKER_CREDENTIALS = credentials('docker-cred-id')  // Configure this in Jenkins
        MAVEN_HOME = tool 'Maven'  // Configure Maven in Jenkins Global Tool Configuration
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Maven Project') {
            agent {
                docker {
                    image 'maven:3.8.4-openjdk-11-slim'
                    args '-v $HOME/.m2:/root/.m2'  // Cache Maven dependencies
                }
            }
            steps {
                script {
                    def mavenProfile = ''
                    if (env.BRANCH_NAME == 'main') {
                        mavenProfile = 'production'
                    } else if (env.BRANCH_NAME == 'staging') {
                        mavenProfile = 'staging'
                    }
                    
                    sh """
                        mvn clean package -P ${mavenProfile} -DskipTests=false
                        mv target/*.jar target/app.jar
                    """
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/app.jar', fingerprint: true
                }
            }
        }

        stage('Run Tests') {
            agent {
                docker {
                    image 'maven:3.8.4-openjdk-11-slim'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                script {
                    def mavenProfile = env.BRANCH_NAME == 'main' ? 'production' : 'staging'
                    sh "mvn test -P ${mavenProfile}"
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def dockerTag = ''
                    def buildArgs = ''
                    
                    if (env.BRANCH_NAME == 'main') {
                        dockerTag = 'production'
                        buildArgs = '--build-arg PROFILE=production'
                    } else if (env.BRANCH_NAME == 'staging') {
                        dockerTag = 'staging'
                        buildArgs = '--build-arg PROFILE=staging'
                    }

                    sh """
                        docker build ${buildArgs} -t ${DOCKER_REGISTRY}/${APP_NAME}:${dockerTag} .
                        docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${dockerTag} ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-cred-id') {
                        def dockerTag = env.BRANCH_NAME == 'main' ? 'production' : 'staging'
                        sh """
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:${dockerTag}
                            docker push ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'staging'
            }
            steps {
                script {
                    sh """
                        docker stop ${APP_NAME}-staging || true
                        docker rm ${APP_NAME}-staging || true
                        docker run -d \
                            --name ${APP_NAME}-staging \
                            -p 8080:8080 \
                            -e SPRING_PROFILES_ACTIVE=staging \
                            -e DB_URL=jdbc:mysql://staging-db:3306/myapp \
                            -e DB_USERNAME=staging_user \
                            -e DB_PASSWORD=staging_pass \
                            ${DOCKER_REGISTRY}/${APP_NAME}:staging
                    """
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                // Optional: Add approval step
                input message: 'Deploy to production?'
                
                script {
                    sh """
                        docker stop ${APP_NAME}-production || true
                        docker rm ${APP_NAME}-production || true
                        docker run -d \
                            --name ${APP_NAME}-production \
                            -p 80:80 \
                            -e SPRING_PROFILES_ACTIVE=production \
                            -e DB_URL=jdbc:mysql://prod-db:3306/myapp \
                            -e DB_USERNAME=prod_user \
                            -e DB_PASSWORD=prod_pass \
                            ${DOCKER_REGISTRY}/${APP_NAME}:production
                    """
                }
            }
        }
    }

    post {
        always {
            // Clean up old docker images
            sh """
                docker image prune -f
                docker container prune -f
            """
            
            // Clean workspace
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
            // Add notification steps here (email, Slack, etc.)
        }
    }
}
