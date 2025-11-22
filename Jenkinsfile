pipeline {
    agent  any  // Jenkins agent with Docker installed

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_REPO     = "amitkumar952/devops-interview-python"  // <-- change this
        DOCKER_CRED_ID  = "amitkumar952-dockerhub"                      // <-- Jenkins credential ID
        IMAGE_TAG       = "${env.GIT_COMMIT?.take(7) ?: env.BUILD_ID}"
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                  echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
                  echo "Commit: $(git rev-parse --short HEAD)"
                '''
            }
        }

        /* ------------------------------------------------
           1. BUILD THE APP (Docker build)
        -------------------------------------------------- */
        stage('Docker Build') {
            when { branch 'main' }
            steps {
                echo "Building Docker image..."
                sh '''
                  sudo docker build \
                    -t ${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG} \
                    -t ${DOCKER_REGISTRY}/${DOCKER_REPO}:latest \
                    .
                '''
            }
        }

        /* ------------------------------------------------
           2. RUN TESTS (Start container + curl endpoints)
        -------------------------------------------------- */
        stage('Endpoint Tests') {
            when { branch 'main' }
            steps {
                echo "Running endpoint tests..."

                sh '''
                  # Start container
                  sudo docker run -d --name test-app -p 5000:5000 ${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG}

                  # Wait for the app to come up
                  sleep 3

                  echo "Testing endpoints..."
                  curl -f http://localhost:5000/        || (docker logs test-app && exit 1)
                  curl -f http://localhost:5000/health  || (docker logs test-app && exit 1)
                  curl -f http://localhost:5000/ready   || (docker logs test-app && exit 1)
                  curl -f http://localhost:5000/metrics || (docker logs test-app && exit 1)
                '''
            }
            post {
                always {
                    sh '''
                      sudo docker stop test-app || true
                      sudo docker rm test-app || true
                    '''
                }
            }
        }

        /* ------------------------------------------------
           3. PUSH TO DOCKER HUB
        -------------------------------------------------- */
        stage('Docker Login & Push') {
            when { branch 'main' }
            steps {
                echo "Pushing Docker image to registry..."

                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CRED_ID}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh '''
                      echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin ${DOCKER_REGISTRY}

                      sudo docker push ${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG}
                      sddo docker push ${DOCKER_REGISTRY}/${DOCKER_REPO}:latest
                    '''
                }
            }
        }

    } // stages

    post {
        success {
            echo "✔ CI pipeline completed. Image pushed successfully."
        }
        failure {
            echo "✖ CI pipeline failed."
        }
        always {
            echo "Pipeline finished."
        }
    }
}

