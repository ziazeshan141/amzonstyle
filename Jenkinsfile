/*
===============================================================================
 MICROservices CI/CD Pipeline
===============================================================================

 Pipeline:
   1. Checkout
   2. Build
   3. Unit Test
   4. SonarQube Analysis
   5. SonarQube Quality Gate
   6. OWASP Dependency Check
   7. Trivy Source Scan
   8. Docker Build
   9. Trivy Docker Image Scan
  10. Docker Push (AWS ECR)
  11. Kubernetes Deployment
  12. Verify Deployment

===============================================================================
*/

def services = [
    'auth-service',
    'user-service',
    'product-service',
    'cart-service',
    'order-service',
    'payment-service',
    'notification-service',
    'api-gateway',
    'frontend',
    'catalog-service',
    'inventory-service',
    'shipping-service',
    'recommendation-service',
    'review-service',
    'search-service',


]

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
        // Configure these names under:
        // Manage Jenkins -> Tools

        jdk 'JDK21'
        maven 'Maven3'
    }

    environment {

        /*
        -----------------------------------------------------------------------
        AWS / ECR Registry
        -----------------------------------------------------------------------
        Registry host format:
            <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

        Fill in your AWS account ID and region below, or move these
        into Jenkins credentials / global properties if you'd rather
        not hardcode them.
        */

        AWS_ACCOUNT_ID = '047385030300'

        AWS_REGION = 'us-east-1'

        REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        /*
        Jenkins Credentials IDs
        */

        // AWS credentials (Access Key / Secret Key) stored as an
        // "AWS Credentials" or "Username/Password" credential in Jenkins.
        //
        // NOTE: if your Jenkins agent already runs on an EC2 instance /
        // EKS pod with an IAM instance role or IRSA that has ECR
        // permissions, you can remove this and the withCredentials
        // block in "Docker Login" entirely - the AWS CLI will pick up
        // credentials automatically.
        AWS_CREDENTIALS = 'aws-ecr-credentials'

        KUBECONFIG_CREDENTIALS = 'kubeconfig'

        NVD_API_KEY_CREDENTIALS = 'nvd-api-key'

        /*
        SonarQube server name configured under:

        Manage Jenkins
        -> System
        -> SonarQube servers
        */

        SONAR_SERVER = 'SonarQube'

        /*
        Kubernetes
        */

        K8S_NAMESPACE = 'microservices'

        /*
        OWASP Dependency Check

        Fail build if CVSS >= 7
        */

        OWASP_CVSS_THRESHOLD = '7'
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

                checkout scm

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
        // Build
        // ====================================================================

        stage('Build Microservices') {

            steps {

                script {

                    services.each { service ->

                        echo """
                        ============================================
                        Building ${service}
                        ============================================
                        """

                        dir(service) {

                            sh '''
                                mvn -B \
                                    clean \
                                    package \
                                    -DskipTests
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

                    services.each { service ->

                        echo """
                        ============================================
                        Running tests: ${service}
                        ============================================
                        """

                        dir(service) {

                            sh '''
                                mvn -B test
                            '''
                        }
                    }
                }
            }

            post {

                always {

                    junit(
                        testResults: '**/target/surefire-reports/*.xml',
                        allowEmptyResults: true
                    )
                }
            }
        }


        // ====================================================================
        // SonarQube
        // ====================================================================

        stage('SonarQube Analysis') {

            steps {

                script {

                    services.each { service ->

                        echo """
                        ============================================
                        SonarQube Scan: ${service}
                        ============================================
                        """

                        dir(service) {

                            withSonarQubeEnv("${SONAR_SERVER}") {

                                sh """
                                    mvn -B sonar:sonar \
                                    -Dsonar.projectKey=${service} \
                                    -Dsonar.projectName=${service}
                                """
                            }
                        }


                        /*
                        -------------------------------------------------------
                        IMPORTANT

                        Wait for the quality gate before analyzing/deploying
                        the next component.
                        -------------------------------------------------------
                        */

                        timeout(
                            time: 10,
                            unit: 'MINUTES'
                        ) {

                            waitForQualityGate(
                                abortPipeline: true
                            )
                        }
                    }
                }
            }
        }


        // ====================================================================
        // OWASP Dependency Check
        // ====================================================================

        stage('OWASP Dependency Check') {

            steps {

                withCredentials([
                    string(
                        credentialsId: "${NVD_API_KEY_CREDENTIALS}",
                        variable: 'NVD_API_KEY'
                    )
                ]) {

                    script {

                        services.each { service ->

                            echo """
                            ============================================
                            OWASP Dependency Check: ${service}
                            ============================================
                            """

                            dir(service) {

                                sh """
                                    mvn -B \
                                    org.owasp:dependency-check-maven:13.0.0:check \
                                    -DfailBuildOnCVSS=${OWASP_CVSS_THRESHOLD} \
                                    -Dformats=HTML,JSON \
                                    -DnvdApiKeyEnvironmentVariable=NVD_API_KEY
                                """
                            }
                        }
                    }
                }
            }

            post {

                always {

                    archiveArtifacts(
                        artifacts: '**/target/dependency-check-report.*',
                        allowEmptyArchive: true
                    )
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

                            /*
                            Generate JSON report
                            */

                            sh """
                                trivy fs \
                                --scanners vuln,secret,misconfig \
                                --severity HIGH,CRITICAL \
                                --skip-dirs target \
                                --format json \
                                --output trivy-fs-report.json \
                                .
                            """


                            /*
                            Fail pipeline for HIGH / CRITICAL
                            vulnerabilities.
                            */

                            sh """
                                trivy fs \
                                --scanners vuln,secret,misconfig \
                                --severity HIGH,CRITICAL \
                                --skip-dirs target \
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

                        /*
                        Generate report
                        */

                        sh """
                            trivy image \
                            --severity HIGH,CRITICAL \
                            --format json \
                            --output trivy-${service}-image.json \
                            ${image}
                        """


                        /*
                        Fail deployment if HIGH/CRITICAL
                        vulnerability exists
                        */

                        sh """
                            trivy image \
                            --severity HIGH,CRITICAL \
                            --exit-code 1 \
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

                /*
                If your Jenkins agent already has an IAM role / IRSA with
                ECR permissions attached, you can drop the withCredentials
                wrapper below and just run the `aws ecr get-login-password`
                line directly - the AWS CLI will resolve credentials from
                the instance/pod role automatically.
                */

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

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIALS}",
                        variable: 'KUBECONFIG'
                    )
                ]) {

                    script {

                        services.each { service ->

                            def image =
                                "${REGISTRY}/${service}:${IMAGE_TAG}"

                            echo """
                            ============================================
                            Deploying ${service}

                            Image:
                            ${image}
                            ============================================
                            """

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

                withCredentials([
                    file(
                        credentialsId: "${KUBECONFIG_CREDENTIALS}",
                        variable: 'KUBECONFIG'
                    )
                ]) {

                    script {

                        services.each { service ->

                            echo """
                            ============================================
                            Checking rollout: ${service}
                            ============================================
                            """

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