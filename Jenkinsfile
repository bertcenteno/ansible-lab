def runAnsiblePlaybook = { String inventoryPath, String extraArgs ->

    sshagent(['ansible-controller-key']) {

        withEnv([
            "INVENTORY_PATH=${inventoryPath}",
            "EXTRA_ARGS=${extraArgs}"
        ]) {

            if (!extraArgs) {
                sh """
                    ssh ${ANSIBLE_CONTROLLER} 'rm -f /home/ansible/.ansible-rollback-status'
                """
                env.ROLLBACK_STATUS = "NOT_REQUIRED"
            }

            def exitCode = sh(
                script: '''
                    set -e

                    echo "$VAULT_PASSWORD" > vault_pass.tmp
                    chmod 600 vault_pass.tmp

                    trap 'rm -f vault_pass.tmp' EXIT

                    scp vault_pass.tmp ${ANSIBLE_CONTROLLER}:${ANSIBLE_DIR}/.vault_pass

                    ssh ${ANSIBLE_CONTROLLER} "
                        trap 'rm -f ${ANSIBLE_DIR}/.vault_pass /home/ansible/.ansible-rollback-status' EXIT

                        cd ${ANSIBLE_DIR}

                        if ansible-playbook \
                            -i inventories/${INVENTORY_PATH}/hosts \
                            ${EXTRA_ARGS} \
                            --vault-password-file .vault_pass \
                            site.yml; then

                            exit 0
                        else
                            if [ -f /home/ansible/.ansible-rollback-status ] && \
                              grep -qx 'SUCCESS' /home/ansible/.ansible-rollback-status; then
                                exit 42
                            else
                                exit 1
                            fi
                        fi
                    "
                ''',
                returnStatus: true
            )

            if (exitCode == 42) {
                env.ROLLBACK_STATUS = "SUCCESS"
                echo "Rollback Status: ${env.ROLLBACK_STATUS}"
            }

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

    parameters {
        string(
            name: 'ARTIFACT_BUILD',
            defaultValue: '',
            description: 'Jenkins build number of the artifact to deploy. Example: 63'
        )

        booleanParam(
            name: 'DEPLOY_PROD',
            defaultValue: false,
            description: 'Enable production deployment. Must be checked to deploy to PROD.'
        )
    }

	options {
    	timestamps()
        disableConcurrentBuilds()
        buildDiscarder(
            logRotator(
                numToKeepStr: '20',
                artifactNumToKeepStr: '10'
            )
        )
        copyArtifactPermission('ansible-deployment-multibranch/main')

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
            else if (env.BRANCH_NAME.startsWith('release/')) {
                env.PIPELINE_TYPE = "RELEASE"
                env.DEPLOY_ENV = "VALIDATION"

            }
            else if (env.BRANCH_NAME == 'main') {

                env.PIPELINE_TYPE = "BRANCH"

                if (params.DEPLOY_PROD) {
                    env.DEPLOY_ENV = "PROD"
                } else {
                    env.DEPLOY_ENV = "VALIDATION"
                }

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

stage('Artifact Selection') {

    when {
        expression {
            return env.DEPLOY_ENV == 'PROD'
        }
    }

    steps {

        script {

            if (!params.ARTIFACT_BUILD?.trim()) {
                error("""
                No artifact build specified.

                Please provide ARTIFACT_BUILD.
                Example: 63
                """.stripIndent().trim())
            }

            if (!(params.ARTIFACT_BUILD.trim() ==~ /^[1-9]\d*$/)) {
                error("""
                Invalid artifact build number.

                ARTIFACT_BUILD must be a positive Jenkins build number.
                Example: 64
                """.stripIndent().trim())
            }

            env.SELECTED_ARTIFACT_BUILD = params.ARTIFACT_BUILD.trim()
            env.ARTIFACT_NAME = "ansible-deployment-build-${env.SELECTED_ARTIFACT_BUILD}.tar.gz"

            echo """
            ============================
            ARTIFACT SELECTION
            ============================
            Environment: ${env.DEPLOY_ENV}
            Artifact Build: #${env.SELECTED_ARTIFACT_BUILD}
            Artifact: ${env.ARTIFACT_NAME}
            ============================
            """
        }
    }
}

stage('Copy Selected Artifact') {

    when {
        expression {
            return env.DEPLOY_ENV == 'PROD'
        }
    }

    steps {

        script {

            echo """
            ============================
            COPY SELECTED ARTIFACT
            ============================
            Source Job: ansible-deployment-multibranch/develop
            Build: #${env.SELECTED_ARTIFACT_BUILD}
            Artifact: ${env.ARTIFACT_NAME}
            ============================
            """

            copyArtifacts(
                projectName: 'ansible-deployment-multibranch/develop',
                selector: specific(env.SELECTED_ARTIFACT_BUILD),
                filter: env.ARTIFACT_NAME,
                fingerprintArtifacts: true
            )

            echo "Selected artifact copied successfully:"
            sh "ls -lh '${env.ARTIFACT_NAME}'"
        }
    }
}

stage('Verify Selected Artifact') {

    when {
        expression {
            return env.DEPLOY_ENV == 'PROD'
        }
    }

    steps {

        sh '''
        echo "===== VERIFY SELECTED ARTIFACT ====="

        test -f "$ARTIFACT_NAME"

        echo "Artifact:"
        ls -lh "$ARTIFACT_NAME"

        echo
        echo "===== ARTIFACT VERSION ====="

        tar -xOzf "$ARTIFACT_NAME" ansible-deployment/VERSION

        echo
        echo "===== VERIFY BUILD NUMBER ====="

        ARTIFACT_BUILD_FROM_VERSION="$(tar -xOzf "$ARTIFACT_NAME" ansible-deployment/VERSION \
            | awk -F= '/^BUILD_NUMBER=/ {print $2}')"

        test -n "$ARTIFACT_BUILD_FROM_VERSION"

        if [ "$ARTIFACT_BUILD_FROM_VERSION" != "$SELECTED_ARTIFACT_BUILD" ]; then
            echo "ERROR: Artifact build number mismatch!"
            echo "Selected build : $SELECTED_ARTIFACT_BUILD"
            echo "Artifact build : $ARTIFACT_BUILD_FROM_VERSION"
            exit 1
        fi

        echo
        echo "===== VERIFY ARTIFACT SOURCE ====="

        ARTIFACT_BRANCH="$(tar -xOzf "$ARTIFACT_NAME" ansible-deployment/VERSION \
            | awk -F= '/^GIT_BRANCH=/ {print $2}')"

        test -n "$ARTIFACT_BRANCH"

        if [ "$ARTIFACT_BRANCH" != "develop" ]; then
            echo "ERROR: Artifact branch mismatch!"
            echo "Expected branch : develop"
            echo "Artifact branch : $ARTIFACT_BRANCH"
            exit 1
        fi

        echo "Artifact source branch verified: $ARTIFACT_BRANCH"

        echo
        echo "Artifact identity verified successfully."
        echo "Selected build : #$SELECTED_ARTIFACT_BUILD"
        echo "Artifact build : #$ARTIFACT_BUILD_FROM_VERSION"
        '''
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

stage('Release Validation') {

    when {
        expression {
            return env.PIPELINE_TYPE == "RELEASE"
        }
    }

    steps {

        echo "Running Release Candidate validation"

        sh '''
        . .ci-venv/bin/activate

        ansible-playbook \
        -i inventories/dev/hosts \
        --syntax-check \
        site.yml
        '''

    }
}

stage('Build Artifact') {

    when {
        expression {
            return env.DEPLOY_ENV != 'PROD'
        }
    }

    steps {

        script {
            env.ARTIFACT_NAME = "ansible-deployment-build-${BUILD_NUMBER}.tar.gz"
        }

        sh '''
        echo "===== BUILD ARTIFACT ====="

        chmod +x scripts/build-artifact.sh

        ./scripts/build-artifact.sh

        echo
        echo "===== VERIFY ARTIFACT ====="

        test -f "$ARTIFACT_NAME"

        tar -tzf "$ARTIFACT_NAME" > /dev/null

        echo "Artifact verified successfully:"
        ls -lh "$ARTIFACT_NAME"
        '''

        echo "===== ARCHIVE ARTIFACT ====="

        archiveArtifacts(
            artifacts: env.ARTIFACT_NAME,
            fingerprint: true
        )
    }
}

stage('Sync Artifact to Ansible Controller') {

        when {
            expression {
                return env.DEPLOY_ENV == "PROD"
            }
        }

    steps {

        sshagent(['ansible-controller-key']) {

            sh '''
            echo "===== SYNC DEPLOYMENT ARTIFACT ====="

            ARTIFACT="$ARTIFACT_NAME"

            test -f "$ARTIFACT"

            echo "Artifact:"
            ls -lh "$ARTIFACT"

            echo
            echo "===== COPY ARTIFACT TO ANSIBLE CONTROLLER ====="

            scp "$ARTIFACT" \
                ${ANSIBLE_CONTROLLER}:/tmp/

            echo
            echo "===== EXTRACT ARTIFACT ====="

            ssh ${ANSIBLE_CONTROLLER} "
                set -e

                rm -rf ${ANSIBLE_DIR}
                mkdir -p ${ANSIBLE_DIR}

                tar -xzf /tmp/${ARTIFACT} \
                    -C ${ANSIBLE_DIR} \
                    --strip-components=1

                rm -f /tmp/${ARTIFACT}

                echo 'Artifact extracted successfully'
                ls -la ${ANSIBLE_DIR}
            "
            '''
        }
    }
}

stage('Install Ansible Dependencies') {

        when {
            expression {
                return env.DEPLOY_ENV == "PROD"
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

stage('Deployment Preview') {

    when {
        expression {
            return env.PIPELINE_TYPE == "PR" ||
                   env.PIPELINE_TYPE == "BRANCH"
        }
    }

    steps {

        script {

            def inventoryPath

            if (env.PIPELINE_TYPE == "PR") {
                inventoryPath = "dev"
            } else {
                inventoryPath = env.DEPLOY_ENV.toLowerCase()
            }

            echo """
            ============================
            Deployment Preview
            Pipeline Type: ${env.PIPELINE_TYPE}
            Environment: ${env.DEPLOY_ENV}
            Inventory: ${inventoryPath}
            Mode: CHECK + DIFF
            ============================
            """

            runAnsiblePlaybook(
                inventoryPath,
                "--check --diff"
            )

        }

    }

}

stage('Molecule Test') {

    agent {
        label 'molecule-runner'
    }

    when {
        expression {
            return env.PIPELINE_TYPE == "PR"
        }
    }

    steps {

        sh '''
        echo "===== MOLECULE TEST ====="
        python3 -m venv .ci-venv

        . .ci-venv/bin/activate
        pip install --upgrade pip

        pip install -r ci-requirements.txt

        molecule --version

        molecule test -s docker_compose
        '''
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
Artifact: ${env.ARTIFACT_NAME}

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
            return env.DEPLOY_ENV == "PROD"
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
                "title": "Artifact",
                "value": "${env.ARTIFACT_NAME}"
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

        def rollbackDisplay = env.ROLLBACK_STATUS ?: "NOT_REQUIRED"

        if (rollbackDisplay == "SUCCESS") {
            rollbackDisplay = "SUCCESSFUL - Last known-good configuration restored"
        }
        else {
            rollbackDisplay = "Not Required"
        }


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
                "title": "Artifact",
                "value": "${env.ARTIFACT_NAME}"
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
              "title": "Rollback",
              "value": "${rollbackDisplay}"
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
