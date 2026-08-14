/*
===============================================================================
 amzonstyle Microservices CI/CD Pipeline (Node.js)
===============================================================================

 Pipeline:
   1. Checkout
   2. Install Dependencies (npm)
   3. Unit Tests (npm)
   4. Trivy Source Scan
   5. Docker Build
   6. Trivy Docker Image Scan
   7. Docker Push (AWS ECR)
   8. Kubernetes Deployment
   9. Verify Deployment

 NOTE: SonarQube and OWASP Dependency Check were removed since they were
 configured for Maven/Java. Re-add later with sonar-scanner CLI and the
 OWASP dependency-check CLI (pointed at each service's package-lock.json)
 if/when you want them back.

 Repo layout expected (one folder per service, each with its own
 package.json + Dockerfile, except 'frontend' which is a static site
 with no package.json):

   auth-service/         user-service/        product-service/
   cart-service/         order-service/       payment-service/
   notification-service/ api-gateway/         catalog-service/
   inventory-service/    shipping-service/    recommendation-service/
   review-service/       search-service/      frontend/

===============================================================================
*/

// All services that get built, scanned, pushed, and deployed
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

// Services with a package.json - these get npm install/test.
// 'frontend' is a static site (no package.json), so it's excluded here.
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
        // Configure this under: Manage Jenkins -> Tools -> NodeJS installations
        // (requires the "NodeJS" plugin)
        nodejs 'Node20'
    }

    environment {

        /*
        -----------------------------------------------------------------------
        AWS / ECR Registry
        -----------------------------------------------------------------------
        */

        AWS_ACCOUNT_ID = '047385030300'

        AWS_REGION = 'us-east-1'

        EKS_CLUSTER_NAME = 'microservices-dev-eks'

        REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        /*
        -----------------------------------------------------------------------
        GitHub repository
        -----------------------------------------------------------------------
        */

        GIT_REPO_URL = 'https://github.com/ziazeshan141/amzonstyle.git'

        GIT_BRANCH = 'main'

        GITHUB_CREDENTIALS = 'github-credentials'

        /*
        Jenkins Credentials IDs
        */

        AWS_CREDENTIALS = 'aws-ecr-credentials'

        /*
        Kubernetes
        */

        K8S_NAMESPACE = 'microservices'
    }


    stages {

        // ====================================================================
        // Checkout
        // ====================================================================

        stage('Checkout') {

            steps {

                echo '=============================='
                echo 'Checking out source code'
                echo '=============================='

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

                    env.IMAGE_TAG =
                        "${env.BUILD_NUMBER}-${env.GIT_SHORT_COMMIT}"

                    echo "Git Commit : ${env.GIT_SHORT_COMMIT}"
                    echo "Image Tag  : ${env.IMAGE_TAG}"
                }
            }
        }


        // ====================================================================
        // Install Dependencies
        // ====================================================================

        stage('Install Dependencies') {

            steps {

                script {

                    npmServices.each { service ->

                        echo """
                        ============================================
                        Installing dependencies: ${service}
                        ============================================
                        """

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


        // ====================================================================
        // Unit Tests
        // ====================================================================

        stage('Unit Tests') {

            steps {

                script {

                    npmServices.each { service ->

                        echo """
                        ============================================
                        Running tests: ${service}
                        ============================================
                        """

                        dir(service) {

                            /*
                            --if-present avoids failing services that
                            don't have a "test" script defined yet.
                            */

                            sh '''
                                npm test --if-present
                            '''
                        }
                    }
                }
            }
        }


        // ====================================================================
        // Trivy Filesystem / Source Code Scan
        // ====================================================================

        stage('Trivy Source Scan') {

            steps {

                script {

                    services.each { service ->

                        echo """
                        ============================================
                        Trivy Source Scan: ${service}
                        ============================================
                        """

                        dir(service) {

                            sh """
                                trivy fs \
                                --scanners vuln,secret,misconfig \
                                --severity HIGH,CRITICAL \
                                --skip-dirs node_modules \
                                --format json \
                                --output trivy-fs-report.json \
                                .
                            """

                            sh """
                                trivy fs \
                                --scanners vuln,secret,misconfig \
                                --severity HIGH,CRITICAL \
                                --skip-dirs node_modules \
                                --exit-code 1 \
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


        // ====================================================================
        // Docker Build
        // ====================================================================

        stage('Docker Build') {

            steps {

                script {

                    services.each { service ->

                        def image =
                            "${REGISTRY}/${service}:${IMAGE_TAG}"

                        echo """
                        ============================================
                        Building Docker Image

                        ${image}
                        ============================================
                        """

                        sh """
                            docker build \
                            --pull \
                            -t ${image} \
                            ./${service}
                        """
                    }
                }
            }
        }


        // ====================================================================
        // Trivy Container Image Scan
        // ====================================================================

        stage('Trivy Docker Image Scan') {

            steps {

                script {

                    services.each { service ->

                        def image =
                            "${REGISTRY}/${service}:${IMAGE_TAG}"

                        echo """
                        ============================================
                        Trivy Docker Image Scan

                        ${image}
                        ============================================
                        """

                        sh """
                            trivy image \
                            --severity HIGH,CRITICAL \
                            --format json \
                            --output trivy-${service}-image.json \
                            ${image}
                        """

                        sh """
                            trivy image \
                            --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --exit-code 0 \
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


        // ====================================================================
        // Docker Login (AWS ECR)
        // ====================================================================

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
                        aws ecr get-login-password \
                            --region "${AWS_REGION}" \
                        | docker login \
                            --username AWS \
                            --password-stdin "${REGISTRY}"
                    '''
                }
            }
        }


        // ====================================================================
        // Ensure ECR Repositories Exist
        // ====================================================================

        stage('Ensure ECR Repositories') {

            when {

                expression {
                    return params.CREATE_ECR_REPOS
                }
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

                            echo """
                            ============================================
                            Checking ECR repository: ${service}
                            ============================================
                            """

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


        // ====================================================================
        // Push Docker Images
        // ====================================================================

        stage('Push Docker Images') {

            steps {

                script {

                    services.each { service ->

                        def image =
                            "${REGISTRY}/${service}:${IMAGE_TAG}"

                        echo """
                        ============================================
                        Pushing Docker Image

                        ${image}
                        ============================================
                        """

                        sh """
                            docker push ${image}
                        """
                    }
                }
            }
        }


        // ====================================================================
        // Kubernetes Deployment
        // ====================================================================

        stage('Deploy to Kubernetes') {

            when {

                allOf {

                    branch 'main'

                    expression {
                        return params.DEPLOY_TO_K8S
                    }
                }
            }

            steps {

                sh '''
                aws eks update-kubeconfig \
                    --region "${AWS_REGION}" \
                    --name "${EKS_CLUSTER_NAME}"
                '''

                script {

                    services.each { service ->

                        def image =
                            "${REGISTRY}/${service}:${IMAGE_TAG}"

                        sh """
                            kubectl \
                            -n ${K8S_NAMESPACE} \
                            set image \
                            deployment/${service} \
                            ${service}=${image}
                        """
                    }
                }
            }
        }


        // ====================================================================
        // Deployment Verification
        // ====================================================================

        stage('Verify Kubernetes Deployment') {

            when {

                allOf {

                    branch 'main'

                    expression {
                        return params.DEPLOY_TO_K8S
                    }
                }
            }

            steps {

                sh '''
                    aws eks update-kubeconfig \
                    --region "${AWS_REGION}" \
                    --name "${EKS_CLUSTER_NAME}"
                '''

                script {

                    services.each { service ->

                        echo "Checking rollout: ${service}"

                        sh """
                            kubectl \
                            -n ${K8S_NAMESPACE} \
                            rollout status \
                            deployment/${service} \
                            --timeout=300s
                        """
                    }
                }
            }
        }
    }


    // ========================================================================
    // POST BUILD
    // ========================================================================

    post {

        success {

            echo '''
            ============================================================
                        CI/CD PIPELINE SUCCESSFUL
            ============================================================
            '''
        }

        failure {

            echo '''
            ============================================================
                        CI/CD PIPELINE FAILED
            ============================================================
            '''
        }

        always {

            echo 'Build completed.'

            sh '''
                docker logout "${REGISTRY}" || true
            '''

            script {

                services.each { service ->

                    sh """
                        docker image rm \
                        ${REGISTRY}/${service}:${IMAGE_TAG} \
                        2>/dev/null || true
                    """
                }
            }
        }
    }
}