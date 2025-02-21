pipeline {
   agent {
        docker { 
            image 'dhilsfu/static-base:main'
            alwaysPull false
        }
    }
    stages {
        stage('Checkout') {
            steps {
                dir('wilde-data') {
                    git branch: 'main', credentialsId: 'GITHUB_DHIL_JENKINS', url: 'https://github.com/sfu-dhil/wilde-data'
                }
            }
        }
        stage('Build') {
            environment { 
                ANT_OPTS = "-Xmx6G"
            }
            steps {
                dir('wilde') {
                    sh "yarn install"
                    withAnt {
                        sh 'ant -f build.xml -Ddata.dir=./wilde-data/data'
                    }
                    archiveArtifacts artifacts: 'public/**/*', followSymlinks: false, onlyIfSuccessful: true
                }
            }
        }
    }
}