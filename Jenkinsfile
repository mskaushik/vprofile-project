pipeline {
    agent any
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
        NEXUSIP = '34.228.59.80'
        NEXUSPORT = '8081'
        NEXUS_GRP_REPO = 'vprofile-maven-group'
        NEXUS_LOGIN = 'nexuslogin'
    }

    stages {
        stage('Build'){
            steps {
                sh 'mvn -s settings.xml -DskipTests clean install'
            }
            post {
                success {
                    echo 'Build succeeded! Archiving the job artifacts...'
                    archiveArtifacts artifacts: '**/target/*.war', fingerprint: true
                }
                failure {
                    echo 'Build failed.'
                }
            }
        }

        stage('Test'){
            steps {
                sh """
                    mvn -s settings.xml test \
                    -Dmaven.repo.local=.m2 \
                    -DSNAP_REPO=${SNAP_REPO} \
                    -DRELEASE_REPO=${RELEASE_REPO} \
                    -DCENTRAL_REPO=${CENTRAL_REPO} \
                    -DNEXUS_USER=${NEXUS_USER} \
                    -DNEXUS_PASS=${NEXUS_PASS} \
                    -DNEXUSIP=${NEXUSIP} \
                    -DNEXUSPORT=${NEXUSPORT} \
                    -DNEXUS_GRP_REPO=${NEXUS_GRP_REPO}
                """
            }
            post {
                success {
                    echo 'Tests passed!'
                }
                failure {
                    echo 'Tests failed.'
                }
            }
        }
        
        stage('Checkstyle Analysis'){
            steps {
                sh """
                    mvn -s settings.xml checkstyle:check \
                    -Dmaven.repo.local=.m2 \
                    -DSNAP_REPO=${SNAP_REPO} \
                    -DRELEASE_REPO=${RELEASE_REPO} \
                    -DCENTRAL_REPO=${CENTRAL_REPO} \
                    -DNEXUS_USER=${NEXUS_USER} \
                    -DNEXUS_PASS=${NEXUS_PASS} \
                    -DNEXUSIP=${NEXUSIP} \
                    -DNEXUSPORT=${NEXUSPORT} \
                    -DNEXUS_GRP_REPO=${NEXUS_GRP_REPO}
                """
            }
            post {
                success {
                    echo 'Checkstyle analysis passed!'
                }
                failure {
                    echo 'Checkstyle analysis failed.'
                }
            }
        }
    }
}