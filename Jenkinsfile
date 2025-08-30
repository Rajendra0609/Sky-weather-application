pipeline {
    agent {
        kubernetes {
            inheritFrom 'kube_l' // This must match the name of your pod template
            defaultContainer 'jnlp' // This matches the container name in your pod template
        }
    }
    tools {
        nodejs 'nodejs'
        maven 'maven'
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
        string(name: 'GIT_BRANCH', defaultValue: 'dev/raj/jen', description: 'Branch to build')
        string(name: 'DOCKERHUBREPO', defaultValue: 'daggu1997/weather', description: 'Docker Hub repository to push the image')
        string(name: 'VERSION', defaultValue: 'latest', description: 'Version of the Docker image')
        string(name: 'DOCKER_HUB_CREDENTIALS_ID', defaultValue: 'docker', description: 'Credentials ID for Docker Hub')
        string(name: 'GITHUB_CREDENTIALS_ID', defaultValue: 'github', description: 'Credentials ID for GitHub access')
        string(name: 'GITHUB_REPO', defaultValue: 'Rajendra0609/Sky-weather-application', description: 'GitHub repository in owner/repo format')
        string(name: 'EMAIL_RECIPIENTS', defaultValue: 'rajendra.daggubati09@gmail.com,srirajendraprasaddaggubati@gmail.com', description: 'Comma-separated list of email recipients')
    }

    environment {
        DOCKER_HUB_CREDENTIALS_ID = 'docker'
        GITHUB_CREDENTIALS_ID = 'github'
        GITHUB_REPO = 'Rajendra0609/Sky-weather-application'
        GITHUB_API_URL = 'https://api.github.com'
        EMAIL_RECIPIENTS = 'rajendra.daggubati09@gmail.com,srirajendraprasaddaggubati@gmail.com'
        TERM = 'xterm-256color'
        GITHUB_TOKEN = 'git_token'
        DOCKER_USER = 'docker_user'
        DOCKER_PASS = 'docker_token'
        SCANNER_HOME = tool 'sonar'
    }

    stages {
        stage('Checkout_startup') {
            steps {
                echo '🔄 Cloning the code'
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: "${params.GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "https://github.com/Rajendra0609/Sky-weather-application.git",
                        credentialsId: 'github_Rajendra0609',
                        name: 'origin'
                    ]]
                ]
                sh 'chmod +x welcome_note.sh'
                sh './welcome_note.sh'
            }
        }
        stage('parallel_build') {
            parallel {
                stage('Build') {
                    steps {
                        echo '🔨 Starting build process...'
                        sh 'chmod +x welcome_note.sh'
                        sh './welcome_note.sh'
                        sh 'npm install'
                        echo '📦 Packaging application...'
                    }
                }
                stage('Build_Application') {
                    steps {
                        echo '🔨 Installing dependencies and building the project...'
                        sh 'chmod +x welcome_note.sh'
                        sh './welcome_note.sh'
                        sh 'rm -rf node_modules package-lock.json'
                        sh 'npm install'
                        echo '✅ Build completed.'
                    }
                }
            }
        }

        stage('Parallel_Test') {
            parallel {
                stage('Unit_Test') {
                    steps {
                        echo '🧪 Running unit tests...'
                        sh 'chmod +x welcome_note.sh'
                        sh './welcome_note.sh'
                        sh 'npm install --save-dev jest supertest jest-junit'
                        sh 'npx jest --ci --reporters=default --reporters=jest-junit'
                        echo '✅ Unit tests completed successfully.'
                    }
                }

                stage('Integration_Test') {
                    steps {
                        sh 'chmod +x welcome_note.sh'
                        sh './welcome_note.sh'
                        sh 'python3 backend/test_weather.py || true'
                        echo '✅ Integration tests completed successfully.'
                    }
                }
            }

            post {
                always {
                    archiveArtifacts artifacts: 'junit.xml', allowEmptyArchive: true
                    junit 'junit.xml'
                }
            }
        }

        stage('Lynis_Scan') {
            when {
                branch 'master'
            }
            steps {
                echo '🔍 Starting Lynis security scan...'
                sh '''
                    chmod +x welcome_note.sh
                    ./welcome_note.sh
                    mkdir -p artifacts/lynis
                    lynis audit system --quiet --report-file artifacts/lynis/lynis-report.log
                    lynis audit system | ansi2html > artifacts/lynis/lynis-report.html
                '''
                archiveArtifacts artifacts: 'artifacts/lynis/lynis-report.*', allowEmptyArchive: true
            }
        }

        stage('SonarQube_Scan') {
    steps {
        echo '🔍 Starting SonarQube scan...'
        script {
            withSonarQubeEnv('sonar') {
                sh '''
                    chmod +x welcome_note.sh
                    ./welcome_note.sh
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectKey=Sky-weather-application \
                    -Dsonar.sources=.   # <-- Update this based on actual structure
                '''
            }
        }
        echo '✅ SonarQube scan completed.'
    }
}


        stage('Docker_Build') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    chmod +x welcome_note.sh
                    ./welcome_note.sh
                    docker images
                    docker version
                    docker build -t ${params.DOCKERHUBREPO}:${params.VERSION} -f Dockerfile .
                '''
            }
        }

        stage('Trivy') {
            steps {
                echo '🔍 Starting Trivy scan...'
                script {
                    def imageName = "${params.DOCKERHUBREPO}:${params.VERSION}"
                    sh """
                        trivy image --format json --output trivy-report.json --severity HIGH,CRITICAL ${imageName} || true
                    """
                }
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
                        dockerImage.push("latest")
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Build & Deploy completed successfully!'
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
            script {
                node('kube_m') {
                    cleanWs()
                }
            }
            echo '🧹 Workspace cleaned'
        }
    }
}



















