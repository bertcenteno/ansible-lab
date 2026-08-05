pipeline {

    agent any

    environment {
        ANSIBLE_CONTROLLER = "ansible@172.26.8.51"
        ANSIBLE_DIR = "/home/ansible/ansible-lab"
        VAULT_PASSWORD = credentials('ansible-vault-password')
    }

    stages {

        stage('Checkout from GitHub') {
            steps {
                checkout scm
            }
        }



        stage('Validate Ansible Syntax') {
            steps {
                sh '''
                echo "$VAULT_PASSWORD" > .vault_pass
                chmod 600 .vault_pass

                ansible-playbook site.yml --syntax-check

                rm -f .vault_pass
                '''
            }
        }


        stage('Sync Repository to Ansible Controller') {
            steps {
                sshagent(['ansible-controller-key']) {
                    sh '''
                    rsync -avz --delete \
                    --exclude ".git" \
                    --exclude ".gitignore" \
                    --exclude "Jenkinsfile" \
                    ./ \
                    ${ANSIBLE_CONTROLLER}:${ANSIBLE_DIR}/
                    '''
                }
            }
        }


        stage('Install Ansible Dependencies') {
            steps {
                sshagent(['ansible-controller-key']) {
                    sh '''
                    ssh ${ANSIBLE_CONTROLLER} "
                    cd ${ANSIBLE_DIR} &&
                    ansible-galaxy collection install -r requirements.yml
                    "
                    '''
                }
            }
        }


        stage('Run Ansible Playbook') {
            steps {
                sshagent(['ansible-controller-key']) {
                    sh '''
                    ssh ${ANSIBLE_CONTROLLER} "
                    cd ${ANSIBLE_DIR} &&
                    echo '${VAULT_PASSWORD}' > .vault_pass &&
                    chmod 600 .vault_pass &&
                    ansible-playbook site.yml &&
                    rm -f .vault_pass
                    "
                    '''
                }
            }
        }

    }


    post {

        success {
            echo 'Deployment completed successfully'
        }


        failure {
            echo 'Deployment failed'
        }


        always {
            sh '''
            rm -f .vault_pass || true
            '''
        }

    }

}
