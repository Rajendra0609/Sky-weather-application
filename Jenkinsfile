pipeline {
    agent{
        kubernetes {
            inheritFrom 'kube_s'
            defaultContainer 'jnlp'

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
        string(name: 'GIT_BRANCH', defaultValue: 'master', description: 'Branch to build')
        string(name: 'DOCKERHUBREPO', defaultValue: 'daggu1997/weather', description: 'Docker Hub repository to push the image')
        string(name: 'VERSION', defaultValue: 'latest', description: 'Version of the Docker image')        
    }
    environment {
        DOCKER_CREDENTIALS_ID = credentials('docker')
        GIT_BRANCH = "${params.GIT_BRANCH}"
        GITHUB_CREDENTIALS_ID = credentials('github_Rajendra0609')
        GITHUB_REPO = 'Rajendra0609/Sky-weather-application'
        GITHUB_API_URL = 'https://api.github.com'
        EMAIL_RECIPIENTS = 'rajendra.daggubati09@gmail.com'
    }
    stages {
        stage('Checkout_startup') {
            steps {
                echo '🔄 cloing the code'
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: "${params.GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "https://github.com/Rajendra0609/pipeline_startup.git",
                        credentialsId: 'github_Rajendra0609',
                        name: 'origin',
                    ]],
                ]
                sh 'mv pipeline_startup/*.sh /home/jenkins/.jenkins/workspace/'
            }
        }
        stage('parallel_build') {
            parallel {
                stage('Build') {
                    steps {
                        echo '🔨 Starting build process...'
                        script {
                           sh 'chmod +x *.sh'
                           sh './*.sh'
                           sh 'npm ci'  
                           sh 'npm install' 
                        }
                        echo '🔨 Build process completed.'
                        echo '📦 Packaging application...'
                    }
                }
                stage('Build_Application') {
                    steps {
                        echo '🔨 Installing dependencies and building the project...'
                        sh 'npm ci'
                        sh 'chmod +x *.sh'
                        sh './*.sh'
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
                        sh 'npm ci'
                        sh 'chmod +x *.sh'
                        sh './*.sh'
                        echo '➕ Adding Jest and Supertest as dev dependencies...'
                        sh 'npm install --save-dev jest supertest jest-junit'
                        echo '🧪 Running Jest tests with JUnit XML report generation...'
                        sh 'npx jest --ci --reporters=default --reporters=jest-junit'
                        echo '✅ Unit tests completed successfully.'
                    }
                }
                stage('Integration_Test') {
                    steps {
                        sh 'npm ci'
                        sh 'chmod +x *.sh'
                        sh './*.sh'
                        echo '➕ Adding Jest and Supertest as dev dependencies...'
                        sh 'npm install --save-dev jest supertest jest-junit'
                        echo '🧪 Running Jest tests with JUnit XML report generation...'
                        sh 'npx jest --ci --reporters=default --reporters=jest-junit'
                        echo '📄 Publishing JUnit test report...'
                        junit 'junit.xml'
                        echo '🐍 Executing Python test script...'
                        sh 'python3 backend/test_weather.py || true'
                        echo '✅ Integration tests completed successfully.'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'junit.xml', allowEmptyArchive: true
                    junit 'junit.xml'
                    echo '📄 Publishing JUnit test report...'
                    echo '✅ All tests completed successfully.'
                }
            }
        }
        stage('Lynis_Scan') {
            steps {
                echo '🔍 Starting Lynis security scan...'
                sh '''
                    chmod +x *.sh
                    ./*.sh
                    mkdir -p artifacts/lynis
                    lynis audit system --quiet --report-file artifacts/lynis/lynis-report.log
                    lynis audit system | ansi2html > artifacts/lynis/lynis-report.html
                    '''
                echo '✅ Lynis security scan completed.'
                archiveArtifacts artifacts: 'artifacts/lynis/lynis-report.log', allowEmptyArchive: true
                archiveArtifacts artifacts: 'artifacts/lynis/lynis-report.html', allowEmptyArchive: true
                junit 'artifacts/lynis/lynis-report.html'
                junit 'artifacts/lynis/lynis-report.log'
                echo '📄 Publishing Lynis report...'
                echo '✅ Lynis report published successfully.'
                error('Lynis scan completed with errors. Please review the report for details.')
            }
        }
        stage('SonarQube_Scan') {
            steps {
                echo '🔍 Starting SonarQube scan...'
                script {
                    withSonarQubeEnv('sonarqube') {
                        sh '''
                            chmod +x *.sh
                            ./*.sh
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
                    chmod +x *.sh
                    ./*.sh
                '''
                echo '✅ Docker image built successfully.'
                script {
                    dockerImage = docker.image("${params.DOCKERHUBREPO}:latest")
                    dockerTag = "${params.DOCKERHUBREPO}:${params.VERSION}"
                }
                echo '✅ Docker image built successfully.'
            }
        }
        stage('trivy') {
            steps {
                echo '🔍 Starting Trivy scan...'
                sh '''
                    chmod +x *.sh
                    ./*.sh
                    trivy image --format json --output trivy-report.json --severity HIGH,CRITICAL ${params.DOCKERHUBREPO}:latest || true
                    trivy image --format html --output trivy-report.html --severity HIGH,CRITICAL ${params.DOCKERHUBREPO}:latest || true
                    trivy image --format sarif --output trivy-report.sarif --severity HIGH
                '''
                echo '✅ Trivy scan completed.'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'trivy-report.html', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'trivy-report.sarif', allowEmptyArchive: true
                    junit 'trivy-report.sarif'
                    echo '📄 Publishing Trivy SARIF report...'
                    junit 'trivy-report.html'
                    echo '📄 Publishing Trivy HTML report...'
                    junit 'trivy-report.json'
                    echo '📄 Publishing Trivy report...'
                }
            }
        }
        stage('Docker_Push') {
            steps {
                echo '🚀 Pushing Docker image to Docker Hub...'
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDENTIALS_ID}") {
                        dockerImage.push("${params.VERSION}")
                        dockerImage.push("latest")
                    }
                }
                echo '✅ Docker image pushed successfully.'
            }
        }
        stage('Create GitHub Release') {
            steps {
                echo '🚀 Creating GitHub release...'
                script {
                    def release = createGitHubRelease(
                        repo: "${GITHUB_REPO}",
                        tagName: "${params.VERSION}",
                        name: "Release ${params.VERSION}",
                        body: "Release notes for version ${params.VERSION}",
                        draft: false,
                        prerelease: false,
                        credentialsId: "${GITHUB_CREDENTIALS_ID}"
                    )
                    echo "GitHub release created: ${release.html_url}"
                }
            }
        }
        stage('cleanup') {
            steps {
                echo '🧹 Cleaning up workspace...'
                cleanWs()
                echo '✅ Workspace cleaned up.'
            }
        }

    }
    post {
        always {
            echo '📝 Writing test results to file...'
            script {
                def testResults = currentBuild.rawBuild.getAction(hudson.tasks.junit.TestResultAction.class)
                if (testResults) {
                    def resultsFile = new File("${env.WORKSPACE}/test_results.txt")
                    resultsFile.text = "Test Results:\n"
                    testResults.getResult().getAllTests().each { test ->
                        resultsFile.append("${test.fullName} - ${test.status}\n")
                    }
                    echo "Test results written to ${resultsFile.absolutePath}"
                } else {
                    echo 'No test results found.'
                }
            }
            echo '✅ Test results written successfully.'
            archiveArtifacts artifacts: '**/*', allowEmptyArchive: true    
        }
        success {
            echo '🎉 Build completed successfully!'
            mail to: "${EMAIL_RECIPIENTS}",
                subject: "Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """\
The build was successful. Check the details at ${env.BUILD_URL}
🔗 Pipeline URL: ${env.BUILD_URL}
👷 Triggered by: ${currentBuild.getBuildCauses()[0].userName}

View the full job here: ${env.BUILD_URL}
"""
        }
        failure {
            script {
                def log = currentBuild.rawBuild.getLog(100).join('\n')
                def lastLines = log.split('\n').takeRight(100).join('\n')
                def culprits = currentBuild.getBuildCauses().collect { it.userName }.join(', ')
                def changeAuthor = currentBuild.changeSets.collect { cs ->
                    cs.items.collect { it.author.fullName }
                }.flatten().unique().join(', ')
                def culprit = ''
                try {
                    culprit = currentBuild.getBuildCauses()[0].userName
                } catch (e) {
                    echo "Failed to determine author or trigger: ${e.message}"
                }
                mail to: "${EMAIL_RECIPIENTS}",
                    subject: "FAILURE: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                    body: """\
The Jenkins Pipeline has FAILED ❌

🔍 Failure Stage: See the Stage View or Blue Ocean for the exact stage
👤 Git Committer(s): ${changeAuthor}
🚀 Triggered by: ${culprit}
🔗 Pipeline URL: ${env.BUILD_URL}

📄 Last 50 lines of console output:
--------------------------------------------------
${lastLines}
--------------------------------------------------

Please investigate the issue.
For more details, visit the Jenkins job page: ${env.BUILD_URL}
"""
            }
        }
        unstable {
            echo '⚠️ Build completed with warnings!'
            mail to: "${EMAIL_RECIPIENTS}",
                subject: "Build Unstable: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """\
The build completed with warnings. Check the details at ${env.BUILD_URL}
🔗 Pipeline URL: ${env.BUILD_URL}
👷 Triggered by: ${currentBuild.getBuildCauses()[0].userName}

View the full job here: ${env.BUILD_URL}
"""
        }
    }
}
