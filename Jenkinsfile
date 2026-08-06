pipeline {

    agent any

	options {
    	timestamps()
	disableConcurrentBuilds()

	}

parameters {

    choice(
        name: 'DEPLOY_ENV',
        choices: [
            'DEV',
            'PROD'
        ],
        description: 'Select deployment environment'
    )

}

    environment {
        ANSIBLE_CONTROLLER = "ansible@172.26.8.51"
        ANSIBLE_DIR = "/home/ansible/ansible-lab"
        VAULT_PASSWORD = credentials('ansible-vault-password')
        TEAMS_WEBHOOK = credentials('teams-webhook-url')
    }

    stages {

        stage('Checkout from GitHub') {
            steps {
                checkout scm
            }
        }
	

stage('Get Git Information') {
    steps {
        script {
            env.GIT_COMMIT_SHORT = sh(
                script: "git rev-parse --short HEAD",
                returnStdout: true
            ).trim()

            env.GIT_BRANCH_NAME = sh(
                script: "git name-rev --name-only HEAD | sed 's#remotes/origin/##'",
                returnStdout: true
            ).trim()

            env.GIT_AUTHOR_NAME = sh(
                script: "git log -1 --pretty=format:%an",
                returnStdout: true
            ).trim()

            env.GIT_REPOSITORY = sh(
                script: "git config --get remote.origin.url | sed 's#.*/##;s/.git\$//'",
                returnStdout: true
            ).trim()
	    env.GIT_COMMIT_MESSAGE = sh(
	    script: "git log -1 --pretty=format:%s",
	    returnStdout: true
	    ).trim()

        }
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

stage('Debug Environment') {

    steps {

        script {

            env.DEPLOY_ENV_VALUE = params.DEPLOY_ENV

            echo "DEPLOY_ENV selected value = '${env.DEPLOY_ENV_VALUE}'"

        }

    }

}

stage('Approval to Deploy') {

    when {
        expression {
            params.DEPLOY_ENV == 'PROD'
        }
    }

    steps {

        script {

            try {

                def approval = input(
                    message: """
Deployment Request |

Environment:${DEPLOY_ENV_VALUE}

Repository: ${GIT_REPOSITORY}
Branch: ${GIT_BRANCH_NAME}
Commit: ${GIT_COMMIT_SHORT}
Message: ${GIT_COMMIT_MESSAGE}
Author: ${GIT_AUTHOR_NAME}
Build: #${BUILD_NUMBER}

Proceed with Ansible deployment?
""",
                    ok: 'Deploy Now',
                    submitterParameter: 'APPROVER'
                )

                env.APPROVER = approval ?: "Unknown"

                echo "Approved By: ${env.APPROVER}"

            }
            catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException err) {

                currentBuild.result = 'ABORTED'

                echo "Deployment aborted by user"

                throw err

            }

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

        env.BUILD_TIME = "${currentBuild.duration / 1000} seconds"
	env.APPROVER_VALUE = env.APPROVER ?: "Not Required"

        def payload = """
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
                "title": "Environment",
                "value": "${params.DEPLOY_ENV}"
              },
              {
                "title": "Status",
                "value": "SUCCESS"
              },
              {
                "title": "Approved By",
                "value": "${APPROVER_VALUE}"
              },
              {
                "title": "Repository",
                "value": "${GIT_REPOSITORY}"
              },
              {
                "title": "Branch",
                "value": "${GIT_BRANCH_NAME}"
              },
              {
                "title": "Commit",
                "value": "${GIT_COMMIT_SHORT}"
              },
              {
                "title": "Message",
                "value": "${GIT_COMMIT_MESSAGE}"
              },
              {
                "title": "Author",
                "value": "${GIT_AUTHOR_NAME}"
              },
              {
                "title": "Duration",
                "value": "${BUILD_TIME}"
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
"""

        sh """
        curl -s \
        -H "Content-Type: application/json" \
        -d '${payload}' "\$TEAMS_WEBHOOK"
        """
    }

}


failure {

    script {

        env.BUILD_TIME = "${currentBuild.duration / 1000} seconds"
        env.APPROVER_VALUE = env.APPROVER ?: "Not Required"

        def payload = """
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
                "title": "Environment",
                "value": "${params.DEPLOY_ENV}"
              },
              {
                "title": "Status",
                "value": "FAILED"
              },
              {
                "title": "Repository",
                "value": "${GIT_REPOSITORY}"
              },
              {
                "title": "Branch",
                "value": "${GIT_BRANCH_NAME}"
              },
              {
                "title": "Commit",
                "value": "${GIT_COMMIT_SHORT}"
              },
              {
                "title": "Message",
                "value": "${GIT_COMMIT_MESSAGE}"
              },
              {
                "title": "Author",
                "value": "${GIT_AUTHOR_NAME}"
              },
              {
                "title": "Duration",
                "value": "${BUILD_TIME}"
              }
            ]
          }
        ]
      }
    }
  ]
}
"""

        sh """
        curl -s \
        -H "Content-Type: application/json" \
        -d '${payload}' "\$TEAMS_WEBHOOK"
        """
    }

}


aborted {

    script {

        sh """
        curl -s \
        -H "Content-Type: application/json" \
        -d @- "\$TEAMS_WEBHOOK" <<EOF
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
            "text": "⏹️ Jenkins Deployment Aborted"
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
                "value": "ABORTED"
              },
	      {
	      "title": "Environment",
	      "value": "${params.DEPLOY_ENV}"
	      },
              {
                "title": "Repository",
                "value": "${GIT_REPOSITORY}"
              },
              {
                "title": "Branch",
                "value": "${GIT_BRANCH_NAME}"
              },
              {
                "title": "Commit",
                "value": "${GIT_COMMIT_SHORT}"
              },
              {
                "title": "Message",
                "value": "${GIT_COMMIT_MESSAGE}"
              },
              {
                "title": "Author",
                "value": "${GIT_AUTHOR_NAME}"
              },
              {
                "title": "Duration",
                "value": "${BUILD_TIME}"
              }
            ]
          }
        ]
      }
    }
  ]
}
EOF
        """

    }

}

}

}
