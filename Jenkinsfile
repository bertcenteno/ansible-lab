def runAnsiblePlaybook = { String inventoryPath, String extraArgs ->

    sshagent(['ansible-controller-key']) {

        withEnv([
            "INVENTORY_PATH=${inventoryPath}",
            "EXTRA_ARGS=${extraArgs}"
        ]) {

            def exitCode = sh(
                script: '''
                    set -e

                    echo "$VAULT_PASSWORD" > vault_pass.tmp
                    chmod 600 vault_pass.tmp

                    trap 'rm -f vault_pass.tmp' EXIT

                    scp vault_pass.tmp ${ANSIBLE_CONTROLLER}:${ANSIBLE_DIR}/.vault_pass

                    ssh ${ANSIBLE_CONTROLLER} "
                        trap 'rm -f ${ANSIBLE_DIR}/.vault_pass' EXIT
                        cd ${ANSIBLE_DIR} &&
                        ansible-playbook \
                        -i inventories/${INVENTORY_PATH}/hosts \
                        ${EXTRA_ARGS} \
                        --vault-password-file .vault_pass \
                        site.yml

                    "
                ''',
                returnStatus: true
            )
		if (exitCode != 0) {
		    error("""
		Ansible execution failed
		Environment: ${env.DEPLOY_ENV}
		Inventory: ${inventoryPath}
		Arguments: ${extraArgs ?: 'None'}
		Exit Code: ${exitCode}
		""".stripIndent().trim())
		}
        }
    }
}

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

stage('Detect Environment') {

    steps {

        script {

            if (env.CHANGE_ID) {

                env.PIPELINE_TYPE = "PR"
                env.DEPLOY_ENV = "VALIDATION"

            }
            else if (env.BRANCH_NAME == 'develop') {

                env.PIPELINE_TYPE = "BRANCH"
                env.DEPLOY_ENV = "DEV"

            }
            else if (env.BRANCH_NAME == 'main') {

                env.PIPELINE_TYPE = "BRANCH"
                env.DEPLOY_ENV = "PROD"

            }
	    else if (env.BRANCH_NAME.startsWith('feature/')) {

                env.PIPELINE_TYPE = "FEATURE"
                env.DEPLOY_ENV = "VALIDATION"
            }
            else {

                error("Unsupported branch: ${env.BRANCH_NAME}")

            }


            echo """
            ============================
            Pipeline Type: ${env.PIPELINE_TYPE}
            Branch: ${env.BRANCH_NAME}
            Environment: ${env.DEPLOY_ENV}
            Change ID: ${env.CHANGE_ID}
            ============================
            """

        }

    }

}

stage('Install CI Dependencies') {

    steps {

        sh '''
        python3 -m venv .ci-venv

        . .ci-venv/bin/activate

        pip install --upgrade pip
        pip install -r ci-requirements.txt
        '''

    }

}

stage('YAML Lint') {

    steps {

        sh '''
        . .ci-venv/bin/activate

        yamllint .
        '''

    }

}

stage('Ansible Lint') {

    steps {

        sh '''
        . .ci-venv/bin/activate

        ansible-lint
        '''

    }

}



stage('PR Validation') {

    when {
        expression {
            env.CHANGE_ID != null
        }
    }

    steps {

        echo "Running Pull Request validation only"

        sh '''
	. .ci-venv/bin/activate

        ansible-playbook \
        -i inventories/dev/hosts \
        --syntax-check \
        site.yml
        '''

    }

}



stage('Sync Repository to Ansible Controller') {

        when {
            expression {
                return env.PIPELINE_TYPE == "BRANCH"
            }
        }
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

        when {
            expression {
                return env.PIPELINE_TYPE == "BRANCH"
            }
        }
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

stage('Validate Ansible Syntax') {

	when {
	    expression {
	        return env.PIPELINE_TYPE == "BRANCH"
	    }
	}

    steps {

        script {

            def inventoryPath = env.DEPLOY_ENV.toLowerCase()

           runAnsiblePlaybook(
	    inventoryPath,
	    "--syntax-check"
	)	 

        }

    }

}

stage('Approval to Deploy') {

    when {
        expression {
            return env.DEPLOY_ENV == 'PROD'
        }
    }

    steps {

        script {

            try {

                def approval = input(
                    message: """
Deployment Request |

Environment:${env.DEPLOY_ENV}

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

    when {
    	expression {
        	return env.PIPELINE_TYPE == "BRANCH"
    	}
	}

    steps {

        script {

            def inventoryPath = env.DEPLOY_ENV.toLowerCase()

           runAnsiblePlaybook(
    		inventoryPath,
	    ""
	) 

        }

    }

}

    }

post {


success {

    script {

        env.BUILD_TIME = "${currentBuild.duration / 1000} seconds"
	env.APPROVER_VALUE = env.APPROVER ?: "Not Required"
	def notificationTitle = env.PIPELINE_TYPE == "PR" ?
	    "✅ Jenkins Validation Successful" :
	    "✅ Jenkins Deployment Successful"

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
	    "text": "${notificationTitle}"
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
                "value": "${env.DEPLOY_ENV}"
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
	def notificationTitle = env.PIPELINE_TYPE == "PR" ?
	    "❌ Jenkins Validation Failed" :
	    "❌ Jenkins Deployment Failed"

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
	    "text": "${notificationTitle}"
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
                "value": "${env.DEPLOY_ENV}"
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

	env.BUILD_TIME = "${currentBuild.duration / 1000} seconds"

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
	      "value": "${env.DEPLOY_ENV}"
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
