/*
===============================================================================
 amzonstyle CI/CD Pipeline (single Node.js app)
===============================================================================

 Pipeline:
   1. Checkout
   2. Install & Build
   3. Unit Test
   4. Trivy Source Scan
   5. Docker Build
   6. Trivy Docker Image Scan
   7. Docker Push (AWS ECR)
   8. Kubernetes Deployment
   9. Verify Deployment

 NOTE: SonarQube and OWASP Dependency Check were removed for now since
 they were configured for Maven/Java. Re-add later with sonar-scanner
 CLI and the OWASP dependency-check CLI (pointed at package-lock.json)
 if/when you want them back.

===============================================================================
*/

def APP_NAME = 'amzonstyle'

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
            description: 'Auto-create ECR repository if it does not already exist'
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
        // Install dependencies
        // ====================================================================

        stage('Install Dependencies') {

            steps {

                echo '=============================='
                echo 'Installing npm dependencies'
                echo '=============================='

                sh '''
                    node -v
                    npm -v
                    npm ci
                '''
            }
        }


        // ====================================================================
        // Unit Tests
        // ====================================================================

        stage('Unit Tests') {

            steps {

                echo '=============================='
                echo 'Running tests'
                echo '=============================='

                /*
                If package.json has no "test" script yet, this will fail.
                Either add a test script, or temporarily replace the line
                below with: sh 'echo "no tests configured yet"'
                */

                sh '''
                    npm test
                '''
            }
        }


        // ====================================================================
        // Trivy Filesystem / Source Code Scan
        // ====================================================================

        stage('Trivy Source Scan') {

            steps {

                echo '=============================='
                echo 'Trivy source scan'
                echo '=============================='

                /*
                Generate JSON report
                */

                sh """
                    trivy fs \
                    --scanners vuln,secret,misconfig \
                    --severity HIGH,CRITICAL \
                    --skip-dirs node_modules \
                    --format json \
                    --output trivy-fs-report.json \
                    .
                """

                /*
                Fail pipeline for HIGH / CRITICAL vulnerabilities.
                Remove/comment this block if you want scans to be
                report-only while you're still stabilizing the pipeline.
                */

                sh """
                    trivy fs \
                    --scanners vuln,secret,misconfig \
                    --severity HIGH,CRITICAL \
                    --skip-dirs node_modules \
                    --exit-code 1 \
                    .
                """
            }

            post {

                always {

                    archiveArtifacts(
                        artifacts: 'trivy-fs-report.json',
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

                    env.IMAGE = "${REGISTRY}/${APP_NAME}:${IMAGE_TAG}"

                    echo """
                    ============================================
                    Building Docker Image

                    ${env.IMAGE}
                    ============================================
                    """

                    sh """
                        docker build \
                        --pull \
                        -t ${env.IMAGE} \
                        .
                    """
                }
            }
        }


        // ====================================================================
        // Trivy Container Image Scan
        // ====================================================================

        stage('Trivy Docker Image Scan') {

            steps {

                echo """
                ============================================
                Trivy Docker Image Scan

                ${env.IMAGE}
                ============================================
                """

                sh """
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --format json \
                    --output trivy-image-report.json \
                    ${env.IMAGE}
                """

                sh """
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    ${env.IMAGE}
                """
            }

            post {

                always {

                    archiveArtifacts(
                        artifacts: 'trivy-image-report.json',
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
        // Ensure ECR Repository Exists
        // ====================================================================

        stage('Ensure ECR Repository') {

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

                    sh """
                        aws ecr describe-repositories \
                            --region ${AWS_REGION} \
                            --repository-names ${APP_NAME} \
                        || aws ecr create-repository \
                            --region ${AWS_REGION} \
                            --repository-name ${APP_NAME} \
                            --image-scanning-configuration scanOnPush=true
                    """
                }
            }
        }


        // ====================================================================
        // Push Docker Image
        // ====================================================================

        stage('Push Docker Image') {

            steps {

                echo """
                ============================================
                Pushing Docker Image

                ${env.IMAGE}
                ============================================
                """

                sh """
                    docker push ${env.IMAGE}
                """
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

                sh """
                    kubectl \
                    -n ${K8S_NAMESPACE} \
                    set image \
                    deployment/${APP_NAME} \
                    ${APP_NAME}=${env.IMAGE}
                """
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

                sh """
                    kubectl \
                    -n ${K8S_NAMESPACE} \
                    rollout status \
                    deployment/${APP_NAME} \
                    --timeout=300s
                """
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

            sh """
                docker image rm ${env.IMAGE} 2>/dev/null || true
            """
        }
    }
}