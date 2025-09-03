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
        GRAFANA_CREDS = credentials('grafana-admin-creds')
        AWS_CREDS = credentials('aws-credentials')
        MONITORING_HOST = '10.0.11.22'  // Replace with your monitoring server IP
        GRAFANA_CREDS = credentials('grafana-admin-creds')
        AWS_CREDS = credentials('aws-monitoring-creds')
        SONARSERVER = 'sonarserver'
        SONARSCANNER = 'sonarscanner'
        SLACK_CHANNEL = 'jenkins-cicd'
        SLACK_TOKEN = credentials('slack-token')
    }

    stages {
        stage('Check Disk Space') {
            steps {
                script {
                    def diskSpace = sh(script: "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'", returnStdout: true).trim()
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

        stage('Setup Monitoring') {
            steps {
                script {
                    // Clone monitoring branch
                    sh '''
                        MONITOR_DIR="monitoring-setup"
                        if [ -d "$MONITOR_DIR" ]; then
                            rm -rf "$MONITOR_DIR"
                        fi
                        git clone -b monitoring-setup https://github.com/mskaushik/vprofile-project.git "$MONITOR_DIR"
                        cd "$MONITOR_DIR/monitoring"
                        
                        # Create data directories
                        mkdir -p data/grafana data/prometheus
                        
                        # Update prometheus.yml with Jenkins IP
                        sed -i "s/your-jenkins-ip:8080/${JENKINS_URL}/g" prometheus.yml
                        
                        # Create .env file
                        cat << EOF > .env
                        AWS_ACCESS_KEY_ID=${AWS_CREDS_USR}
                        AWS_SECRET_ACCESS_KEY=${AWS_CREDS_PSW}
                        AWS_REGION=us-east-1
                        GRAFANA_ADMIN_PASSWORD=${GRAFANA_CREDS_PSW}
                        EOF
                        
                        # Start monitoring stack
                        docker-compose down || true
                        docker-compose up -d
                        
                        # Wait for Grafana to be ready
                        echo "Waiting for Grafana to start..."
                        for i in {1..30}; do
                            if curl -s http://localhost:3000/api/health; then
                                break
                            fi
                            sleep 5
                        done
                        
                        # Configure Grafana using API
                        # Add Prometheus data source
                        curl -X POST -H "Content-Type: application/json" -d '{
                            "name":"Prometheus",
                            "type":"prometheus",
                            "url":"http://prometheus:9090",
                            "access":"proxy",
                            "isDefault":true
                        }' http://admin:${GRAFANA_CREDS_PSW}@localhost:3000/api/datasources
                        
                        # Add CloudWatch data source
                        curl -X POST -H "Content-Type: application/json" -d '{
                            "name":"CloudWatch",
                            "type":"cloudwatch",
                            "jsonData": {
                                "authType": "credentials",
                                "defaultRegion": "us-east-1"
                            },
                            "secureJsonData": {
                                "accessKey": "'${AWS_CREDS_USR}'",
                                "secretKey": "'${AWS_CREDS_PSW}'"
                            }
                        }' http://admin:${GRAFANA_CREDS_PSW}@localhost:3000/api/datasources
                        
                        # Import dashboard
                        curl -X POST -H "Content-Type: application/json" -d @dashboard.json http://admin:${GRAFANA_CREDS_PSW}@localhost:3000/api/dashboards/db
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                cleanWs()
                sh '''
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
                '''
                archiveArtifacts artifacts: 'cleanup-report.txt', allowEmptyArchive: true
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed'
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}