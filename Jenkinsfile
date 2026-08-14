def services = [
    'auth-service',
    'user-service',
    'product-service',
    'cart-service',
    'order-service',
    'payment-service',
    'notification-service',
    'api-gateway',
    'catalog-service',
    'inventory-service',
    'shipping-service',
    'recommendation-service',
    'review-service',
    'search-service',
    'frontend'
]

def npmServices = services - ['frontend']

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(
            logRotator(
                numToKeepStr: '20',
                artifactNumToKeepStr: '10'
            )
        )
        skipDefaultCheckout(true)
    }

    parameters {
        booleanParam(
            name: 'DEPLOY_TO_K8S',
            defaultValue: true,
            description: 'Deploy application to Kubernetes'
        )
        booleanParam(
            name: 'CREATE_ECR_REPOS',
            defaultValue: false,
            description: 'Auto-create ECR repositories if they do not already exist'
        )
    }

    tools {
        nodejs 'Node20'
    }

    environment {
        AWS_ACCOUNT_ID     = '047385030300'
        AWS_REGION         = 'us-east-1'
        EKS_CLUSTER_NAME   = 'microservices-dev-eks'
        REGISTRY           = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        GIT_REPO_URL       = 'https://github.com/ziazeshan141/amzonstyle.git'
        GIT_BRANCH         = 'main'
        GITHUB_CREDENTIALS = 'github-credentials'
        AWS_CREDENTIALS    = 'aws-ecr-credentials'
        K8S_NAMESPACE      = 'microservices'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "${GIT_REPO_URL}",
                        credentialsId: "${GITHUB_CREDENTIALS}"
                    ]]
                ])

                script {
                    env.GIT_SHORT_COMMIT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_SHORT_COMMIT}"

                    echo "Git Commit : ${env.GIT_SHORT_COMMIT}"
                    echo "Image Tag  : ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    npmServices.each { service ->
                        echo "Installing dependencies: ${service}"
                        dir(service) {
                            sh '''
                                node -v
                                npm -v
                                npm ci
                            '''
                        }
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    npmServices.each { service ->
                        echo "Running tests: ${service}"
                        dir(service) {
                            sh 'npm test --if-present'
                        }
                    }
                }
            }
        }

        stage('Trivy Source Scan') {
            steps {
                script {
                    services.each { service ->
                        echo "Trivy Source Scan: ${service}"
                        dir(service) {
                            // Generate JSON report without failing build immediately
                            sh """
                                trivy fs \
                                    --scanners vuln,secret,misconfig \
                                    --severity HIGH,CRITICAL \
                                    --skip-dirs node_modules \
                                    --format json \
                                    --output trivy-fs-report.json \
                                    .
                            """
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts(
                        artifacts: '**/trivy-fs-report.json',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    services.each { service ->
                        def image = "${REGISTRY}/${service}:${IMAGE_TAG}"
                        echo "Building Docker Image: ${image}"
                        sh "docker build --pull -t ${image} ./${service}"
                    }
                }
            }
        }

        stage('Trivy Docker Image Scan') {
            steps {
                script {
                    services.each { service ->
                        def image = "${REGISTRY}/${service}:${IMAGE_TAG}"
                        echo "Trivy Docker Image Scan: ${image}"
                        sh """
                            trivy image \
                                --severity HIGH,CRITICAL \
                                --format json \
                                --output trivy-${service}-image.json \
                                ${image}
                        """
                    }
                }
            }
            post {
                always {
                    archiveArtifacts(
                        artifacts: 'trivy-*-image.json',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${AWS_CREDENTIALS}",
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        aws ecr get-login-password --region "${AWS_REGION}" | \
                        docker login --username AWS --password-stdin "${REGISTRY}"
                    '''
                }
            }
        }

        stage('Ensure ECR Repositories') {
            when {
                expression { return params.CREATE_ECR_REPOS }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${AWS_CREDENTIALS}",
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        services.each { service ->
                            echo "Checking ECR repository: ${service}"
                            sh """
                                aws ecr describe-repositories \
                                    --region ${AWS_REGION} \
                                    --repository-names ${service} \
                                || aws ecr create-repository \
                                    --region ${AWS_REGION} \
                                    --repository-name ${service} \
                                    --image-scanning-configuration scanOnPush=true
                            """
                        }
                    }
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                script {
                    services.each { service ->
                        def image = "${REGISTRY}/${service}:${IMAGE_TAG}"
                        echo "Pushing Docker Image: ${image}"
                        sh "docker push ${image}"
                    }
                }
            }
        }

        stage('Deploy & Verify Kubernetes') {
            when {
                allOf {
                    branch 'main'
                    expression { return params.DEPLOY_TO_K8S }
                    // If parameter is null (first run), default to true; otherwise check parameter value
                    return params.DEPLOY_TO_K8S == null ? true : params.DEPLOY_TO_K8S
                }
            }
            steps {
                // Corrected credential ID reference
                withCredentials([
                    usernamePassword(
                        credentialsId: "${AWS_CREDENTIALS}",
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        aws eks update-kubeconfig \
                            --region "${AWS_REGION}" \
                            --name "${EKS_CLUSTER_NAME}"
                    '''

                    script {
                        services.each { service ->
                            def image = "${REGISTRY}/${service}:${IMAGE_TAG}"

                            echo "Deploying ${service} image: ${image}"
                            sh """
                                kubectl -n ${K8S_NAMESPACE} set image \
                                    deployment/${service} \
                                    ${service}=${image}
                            """

                            echo "Checking rollout status for: ${service}"
                            sh """
                                kubectl -n ${K8S_NAMESPACE} rollout status \
                                    deployment/${service} \
                                    --timeout=300s
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD PIPELINE SUCCESSFUL'
        }
        failure {
            echo 'CI/CD PIPELINE FAILED'
        }
        always {
            echo 'Build completed.'
            sh 'docker logout "${REGISTRY}" || true'
            script {
                services.each { service ->
                    sh "docker image rm ${REGISTRY}/${service}:${IMAGE_TAG} 2>/dev/null || true"
                }
            }
        }
    }
}