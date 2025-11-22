pipeline {
    agent any  // Jenkins agent with Docker installed

    environment {
        DOCKER_REGISTRY = "docker.io"
        DOCKER_REPO     = "amitkumar952/devops-interview-python"
        DOCKER_CRED_ID  = "amitkumar952-dockerhub"
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

        stage('Docker Build') {
            when { branch 'main' }
            steps {
                echo "Building Docker image..."
                sh '''
                  docker build \
                    -t ${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG} \
                    -t ${DOCKER_REGISTRY}/${DOCKER_REPO}:latest \
                    .
                '''
            }
        }

        stage('Endpoint Tests') {
            when { branch 'main' }
            steps {
                echo "Running endpoint tests..."

                sh '''
                  docker run -d --name test-app -p 5000:5000 ${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG}
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
                      docker stop test-app || true
                      docker rm test-app || true
                    '''
                }
            }
        }

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

                      docker push ${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG}
                      docker push ${DOCKER_REGISTRY}/${DOCKER_REPO}:latest
                    '''
                }
            }
        }

        /* ------------------------------------------------
           4. DEPLOY TO KUBERNETES
        -------------------------------------------------- */
        stage('Deploy to Kubernetes') {
            when { branch 'main' }
            steps {
                echo "Deploying to Kubernetes..."

                withCredentials([
                    file(credentialsId: 'KUBECONFIG_CRED', variable: 'KUBECONFIG_FILE'),
                    string(credentialsId: 'APP_API_KEY', variable: 'REAL_API_KEY')
                ]) {
                    sh '''
                      export KUBECONFIG=${KUBECONFIG_FILE}

                      echo "Applying ConfigMap, Service, HPA, PDB..."
                      kubectl apply -f k8s/configmap.yaml
                      kubectl apply -f k8s/service.yaml
                      kubectl apply -f k8s/hpa.yaml
                      kubectl apply -f k8s/pdb.yaml || true

                      echo "Creating/Updating Kubernetes Secret from Jenkins credential..."
                      kubectl create secret generic devops-python-secret \
                        --from-literal=api_key="${REAL_API_KEY}" \
                        --dry-run=client -o yaml | kubectl apply -f -

                      echo "Updating Deployment image for rolling update..."
                      kubectl -n default set image deployment/devops-python \
                        devops-python=${DOCKER_REGISTRY}/${DOCKER_REPO}:${IMAGE_TAG} --record

                      echo "Waiting for Rolling Update to Complete..."
                      kubectl -n default rollout status deployment/devops-python --timeout=120s
                    '''
                }
            }

            post {
                failure {
                    echo "Deployment failed — attempting rollback..."
                    script {
                        withCredentials([file(credentialsId: 'KUBECONFIG_CRED', variable: 'KUBECONFIG_FILE')]) {
                            sh '''
                              export KUBECONFIG=${KUBECONFIG_FILE}
                              kubectl -n default rollout undo deployment/devops-python
                              kubectl -n default rollout status deployment/devops-python --timeout=60s || true
                            '''
                        }
                    }
                }
                success {
                    echo "✔ Deployment succeeded."
                }
            }
        }

    }

    post {
        success {
            echo "✔ CI/CD pipeline completed successfully."
        }
        failure {
            echo "✖ CI/CD pipeline failed."
        }
        always {
            echo "Pipeline finished."
        }
    }
}

