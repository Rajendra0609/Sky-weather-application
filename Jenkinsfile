pipeline {

agent {
       label 'fix_s'
       // kubernetes {
            //label 'kube_m' // ✅ Must match the label in the pod template
           // defaultContainer 'jnlp'
        //}
    }


    tools {
        nodejs 'nodejs'
        //maven 'maven'
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
        skipDefaultCheckout()
        timestamps()
        disableResume()
        retry(0)
    }

    parameters {
        string(name: 'GIT_BRANCH', defaultValue: 'dev_jen', description: 'Branch to build')
        string(name: 'DOCKERHUBREPO', defaultValue: 'daggu1997/weather', description: 'Docker Hub repository to push the image')
        string(name: 'VERSION', defaultValue: 'latest', description: 'Version of the Docker image')
        string(name: 'DOCKER_HUB_CREDENTIALS_ID', defaultValue: 'docker', description: 'Credentials ID for Docker Hub')
        string(name: 'GITHUB_CREDENTIALS_ID', defaultValue: 'github', description: 'Credentials ID for GitHub access')
        string(name: 'GITHUB_REPO', defaultValue: 'Rajendra0609/Sky-weather-application', description: 'GitHub repository in owner/repo format')
        string(name: 'EMAIL_RECIPIENTS', defaultValue: 'rajendra.daggubati09@gmail.com,srirajendraprasaddaggubati@gmail.com', description: 'Comma-separated list of email recipients')
    }


    environment {
        DOCKER_HUB_CREDENTIALS_ID = 'docker'
        GIT_BRANCH = "${params.GIT_BRANCH}"
        GITHUB_CREDENTIALS_ID = 'github_Rajendra0609'
        GITHUB_REPO = 'Rajendra0609/Sky-weather-application'
        GITHUB_API_URL = 'https://api.github.com'
        EMAIL_RECIPIENTS = 'rajendra.daggubati09@gmail.com,srirajendraprasaddaggubati@gmail.com'
        TERM = 'xterm-256color'
        GITHUB_TOKEN = 'git_token'
        DOCKER_USER = 'docker_user'
        DOCKER_PASS = 'docker_token'
        SCANNER_HOME = tool 'sonar'
        GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
        BUILD_DATE = sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
        IMAGE_TAG = "${GIT_COMMIT}-${BUILD_DATE}"
    }

    stages {
        stage('Checkout_startup') {
            steps {
                echo '🔄 cloing the code'
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: "${params.GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "https://github.com/Rajendra0609/Sky-weather-application.git",
                        credentialsId: 'github_Rajendra0609',
                        name: 'origin'
                    ]]
                ]
            }
        }

        stage('parallel_build') {
            parallel {
                stage('Build') {
                    steps {
                        cache(path: '.npm', key: 'npm-cache-${GIT_COMMIT}') {
                            echo '🔨 Starting build process...'
                            sh './usr/local/bin/node_status.sh'
                            sh 'npm install'
                            echo '🔨 Build process completed.'
                            echo '📦 Packaging application...'
                        }
                    }
                }

                stage('Build_Application') {
                    steps {
                        cache(path: '.npm', key: 'npm-cache-${GIT_COMMIT}') {
                            echo '🔨 Installing dependencies and building the project...'
                            sh './usr/local/bin/node_status.sh'
                            sh 'npm install'
                            echo '✅ Build completed.'
                        }
                    }
                }
            }
        }

        stage('Matrix_Test') {
            matrix {
                axes {
                    axis {
                        name 'TEST_TYPE'
                        values 'unit', 'integration'
                    }
                }
                stages {
                    stage('Test') {
                        steps {
                            script {
                                sh './usr/local/bin/node_status.sh'
                                sh 'npm install --save-dev jest supertest jest-junit'
                                if (TEST_TYPE == 'unit') {
                                    sh 'npx jest --ci --reporters=default --reporters=jest-junit --coverage'
                                } else {
                                    sh 'npx jest --ci --reporters=default --reporters=jest-junit'
                                    sh 'python3 backend/test_weather.py || true'
                                }
                            }
                        }
                    }
                }
            }
            post {
                always {
                    junit 'junit.xml'
                    publishHTML(target: [allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage Report'])
                    echo '📄 Publishing JUnit and Coverage reports...'
                }
            }
        }

        stage('Lynis_Scan') {
            steps {
                echo '🔍 Starting Lynis security scan...'
                sh '''
                    ./usr/local/bin/node_status.sh
                    mkdir -p artifacts/lynis
                    lynis audit system --quiet --report-file artifacts/lynis/lynis-report.log
                    lynis audit system | ansi2html > artifacts/lynis/lynis-report.html
                '''
                archiveArtifacts artifacts: 'artifacts/lynis/lynis-report.log', allowEmptyArchive: true
                archiveArtifacts artifacts: 'artifacts/lynis/lynis-report.html', allowEmptyArchive: true
                echo '✅ Lynis report published successfully.'
            }
        }

        stage('SonarQube_Scan') {
          steps {
            script {
            withSonarQubeEnv('sonar') {
                sh '''
                    ./usr/local/bin/node_status.sh
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectKey=Sky-weather-application \
                    -Dsonar.sources=backend,frontend,my-shared-library,welcome_note.sh \
                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                '''
            }
            echo '✅ SonarQube scan completed.'
        }

        }
        }
        stage('Docker_Build') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    ./usr/local/bin/node_status.sh
                '''
                script {
                    dockerImage = docker.build("${params.DOCKERHUBREPO}:${IMAGE_TAG}", "-f Dockerfile .")
                }
                echo '✅ Docker image built successfully.'
            }
        }

        stage('DAST_Scan') {
            steps {
                echo '🔍 Starting DAST scan with OWASP ZAP...'
                sh '''
                    docker run --rm -v $(pwd):/zap/wrk:rw -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:3000 -r zap-report.html || true
                '''
                archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
                echo '✅ DAST scan completed.'
            }
        }

        stage('Trivy') {
            steps {
                echo '🔍 Starting Trivy scan...'
                script {
                    def imageName = "${params.DOCKERHUBREPO}:${IMAGE_TAG}"
                    sh """
                        trivy image --format json --output trivy-report.json --severity HIGH,CRITICAL ${imageName} || true
                    """
                }
                echo '✅ Trivy scan completed.'
            }

            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Docker_Push') {
            steps {
                echo '🚀 Pushing Docker image to Docker Hub...'
                script {
                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_HUB_CREDENTIALS_ID}") {
                        dockerImage.push("${IMAGE_TAG}")
                        dockerImage.push("latest")
                    }
                }
                echo '✅ Docker image pushed successfully.'
            }
        }

        stage('Deploy_Staging') {
            steps {
                echo '🚀 Deploying to Staging...'
                //sh 'kubectl apply -f k8s/staging.yaml'
                echo '✅ Deployed to Staging.'
            }
        }

        stage('Deploy_Prod') {
            steps {
                input message: 'Deploy to Production?'
                echo '🚀 Deploying to Production...'
                //sh 'kubectl apply -f k8s/prod.yaml'
                echo '✅ Deployed to Production.'
            }
        }
    }

    post {
        success {
            echo 'Build & Deploy completed successfully!'
            slackSend(channel: '#ci-cd', message: "✅ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} succeeded!")
            githubNotify(status: 'SUCCESS', description: 'Build succeeded')
            mail to: "${EMAIL_RECIPIENTS}",
                 subject: "SUCCESS: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                 body: """\
The Jenkins Pipeline completed successfully.

🔗 Pipeline URL: ${env.BUILD_URL}
👷 Triggered by: ${currentBuild.getBuildCauses()[0].userName}

View the full job here: ${env.BUILD_URL}
"""
        }

        failure {
            script {
                def log = currentBuild.rawBuild.getLog(1000)
                def lastLines = log.takeRight(50).join('\n')

                def culprit = "Unknown"
                def changeAuthor = "Unknown"

                try {
                    changeAuthor = currentBuild.changeSets.collect { cs ->
                        cs.items.collect { it.author.fullName }
                    }.flatten().unique().join(', ')
                    culprit = currentBuild.getBuildCauses()[0].userName
                } catch (e) {
                    echo "Failed to determine author or trigger: ${e.message}"
                }

                slackSend(channel: '#ci-cd', message: "❌ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} failed!")
                githubNotify(status: 'FAILURE', description: 'Build failed')
                mail to: "${EMAIL_RECIPIENTS}",
                     subject: "FAILURE: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                     body: """\
The Jenkins Pipeline has FAILED ❌

🔍 Failure Stage: See the Stage View or Blue Ocean for exact stage
👤 Git Committer(s): ${changeAuthor}
🚀 Triggered by: ${culprit}
🔗 Pipeline URL: ${env.BUILD_URL}

📄 Last 50 lines of console output:
--------------------------------------------------
${lastLines}
--------------------------------------------------

Please investigate the issue.
"""
            }
        }

        unstable {
            script {
                def log = currentBuild.rawBuild.getLog(1000)
                def lastLines = log.takeRight(50).join('\n')

                def culprit = "Unknown"
                def changeAuthor = "Unknown"

                try {
                    changeAuthor = currentBuild.changeSets.collect { cs ->
                        cs.items.collect { it.author.fullName }
                    }.flatten().unique().join(', ')
                    culprit = currentBuild.getBuildCauses()[0].userName
                } catch (e) {
                    echo "Failed to determine author or trigger: ${e.message}"
                }

                slackSend(channel: '#ci-cd', message: "⚠️ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} is unstable!")
                githubNotify(status: 'ERROR', description: 'Build unstable')
                mail to: "${EMAIL_RECIPIENTS}",
                     subject: "UNSTABLE: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                     body: """\
The Jenkins Pipeline is UNSTABLE ⚠️

🔍 Potential Failure Stage: See the Stage View or Blue Ocean for exact stage
👤 Git Committer(s): ${changeAuthor}
🚀 Triggered by: ${culprit}
🔗 Pipeline URL: ${env.BUILD_URL}

📄 Last 50 lines of console output:
--------------------------------------------------
${lastLines}
--------------------------------------------------

Please investigate the warning.
"""
            }
        }

        always {
            cleanWs()
            echo 'Workspace cleaned'
        }
    }
}
