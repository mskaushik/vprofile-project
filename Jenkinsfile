pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '5', daysToKeepStr: '5'))
    }
    tools {
        maven "MAVEN-3.9"
        jdk "JDK-17"
    }
    
    environment {
        SNAP_REPO = 'vprofile-snapshot'
        NEXUS_USER = 'admin'
        NEXUS_PASS = 'admin@123'
        RELEASE_REPO = 'vprofile-release'
        CENTRAL_REPO = 'vpro-maven-central'
        NEXUSIP = '10.0.11.22'
        NEXUSPORT = '8081'
        NEXUS_GRP_REPO = 'vprofile-maven-group'
        NEXUS_LOGIN = 'nexus_login'
        SONARSERVER = 'sonarserver'
        SONARSCANNER = 'sonarscanner'
    }

    stages {
        stage('Check Disk Space') {
            steps {
                script {
                    def diskSpace = sh(script: 'df -h / | tail -1 | awk \'{print $5}\' | sed \'s/%//\'', returnStdout: true).trim()
                    if (diskSpace.toInteger() > 80) {
                        error "Disk space is critically low (${diskSpace}%). Aborting build."
                    } else if (diskSpace.toInteger() > 70) {
                        echo "Warning: Disk space is getting high (${diskSpace}%)"
                    }
                }
            }
        }

        stage('Build'){
            steps {
                sh 'mvn -s settings.xml -DskipTests install'
            }
            post {
                success {
                    echo "Now Archiving."
                    archiveArtifacts artifacts: '**/*.war'
                }
            }
        }

        stage('Test'){
            steps {
                sh 'mvn -s settings.xml test'
            }

        }

        stage('Checkstyle Analysis'){
            steps {
                sh 'mvn -s settings.xml checkstyle:checkstyle'
            }
        }

        stage('Sonar Analysis') {
            environment {
                scannerHome = tool "${SONARSCANNER}"
            }
            steps {
               withSonarQubeEnv("${SONARSERVER}") {
                   sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
                   -Dsonar.projectName=vprofile \
                   -Dsonar.projectVersion=1.0 \
                   -Dsonar.sources=src/ \
                   -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                   -Dsonar.junit.reportsPath=target/surefire-reports/ \
                   -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                   -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
              }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                    // true = set pipeline to UNSTABLE, false = don't
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("UploadArtifact"){
            steps{
                nexusArtifactUploader(
                  nexusVersion: 'nexus3',
                  protocol: 'http',
                  nexusUrl: "${NEXUSIP}:${NEXUSPORT}",
                  groupId: 'QA',
                  version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                  repository: "${RELEASE_REPO}",
                  credentialsId: "${NEXUS_LOGIN}",
                  artifacts: [
                    [artifactId: 'vproapp',
                     classifier: '',
                     file: 'target/vprofile-v2.war',
                     type: 'war']
                  ]
                )
            }
        }

        stage('Cleanup') {
            steps {
                cleanWs()
                sh """
                    echo "Cleaning up workspace..."
                    # Remove build artifacts
                    rm -rf target/
                    rm -rf .m2/
                    
                    # Clean up Docker (if using)
                    docker system prune -f || true
                    
                    # Clean up old logs
                    sudo find /var/log/jenkins -name "*.log.*" -type f -mtime +7 -delete || true
                    
                    # Clean up temp files
                    sudo rm -rf /tmp/jenkins* || true
                    
                    echo "Disk space after cleanup:"
                    df -h /
                    
                    # Archive cleanup report
                    echo "Cleanup completed at $(date)" > cleanup-report.txt
                    echo "Current disk usage:" >> cleanup-report.txt
                    df -h / >> cleanup-report.txt
                """
                archiveArtifacts artifacts: 'cleanup-report.txt', allowEmptyArchive: true
            }
        }
    }
}