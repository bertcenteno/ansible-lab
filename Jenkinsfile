pipeline {

    agent any

	options {
    	timestamps()
	disableConcurrentBuilds()

	}

    environment {
        ANSIBLE_CONTROLLER = "ansible@172.26.8.51"
        ANSIBLE_DIR = "/home/ansible/ansible-lab"
        VAULT_PASSWORD = credentials('ansible-vault-password')
        TEAMS_WEBHOOK = credentials('teams-webhook-url')
	BUILD_TIME = ""
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
		    echo "$VAULT_PASSWORD" > vault_pass.tmp
	            chmod 600 vault_pass.tmp

            		scp vault_pass.tmp ${ANSIBLE_CONTROLLER}:${ANSIBLE_DIR}/.vault_pass

            		ssh ${ANSIBLE_CONTROLLER} "
            		cd ${ANSIBLE_DIR} &&
        	    ansible-playbook site.yml
	            "

       		     ssh ${ANSIBLE_CONTROLLER} "
       	   	  	rm -f ${ANSIBLE_DIR}/.vault_pass
   	        	 "

	            rm -f vault_pass.tmp

                    '''
                }
            }
        }

    }

post {

    success {

        script {
            BUILD_TIME = currentBuild.durationString
        }

        echo 'Deployment completed successfully'

        sh '''
        curl -s \
        -H "Content-Type: application/json" \
        -d @- "$TEAMS_WEBHOOK" <<EOF || true
{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.4",
        "body": [
          {
            "type": "TextBlock",
            "size": "Large",
            "weight": "Bolder",
            "text": "✅ Jenkins Deployment Successful"
          },
          {
            "type": "FactSet",
            "facts": [
              {
                "title": "Job",
                "value": "${JOB_NAME}"
              },
              {
                "title": "Build",
                "value": "#${BUILD_NUMBER}"
              },
              {
                "title": "Status",
                "value": "SUCCESS"
              },
              {
                "title": "Duration",
                "value": "${currentBuild.durationString}"
              }
            ]
          },
          {
            "type": "ActionSet",
            "actions": [
              {
                "type": "Action.OpenUrl",
                "title": "View Jenkins Build",
                "url": "${BUILD_URL}"
              }
            ]
          }
        ]
      }
    }
  ]
}
EOF
        '''
    }


    failure {

        script {
            BUILD_TIME = currentBuild.durationString
        }

        echo 'Deployment failed'

        sh '''
        curl -s \
        -H "Content-Type: application/json" \
        -d @- "$TEAMS_WEBHOOK" <<EOF || true
{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.4",
        "body": [
          {
            "type": "TextBlock",
            "size": "Large",
            "weight": "Bolder",
            "text": "❌ Jenkins Deployment Failed"
          },
          {
            "type": "FactSet",
            "facts": [
              {
                "title": "Job",
                "value": "${JOB_NAME}"
              },
              {
                "title": "Build",
                "value": "#${BUILD_NUMBER}"
              },
              {
                "title": "Status",
                "value": "FAILED"
              },
              {
                "title": "Duration",
                "value": "${currentBuild.durationString}"
              }
            ]
          },
          {
            "type": "ActionSet",
            "actions": [
              {
                "type": "Action.OpenUrl",
                "title": "View Jenkins Build",
                "url": "${BUILD_URL}"
              }
            ]
          }
        ]
      }
    }
  ]
}
EOF
        '''
    }

}

}
