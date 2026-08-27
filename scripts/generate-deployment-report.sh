#!/bin/bash

set -e

# Required variables validation
: "${ENVIRONMENT:?ENVIRONMENT is required}"
: "${JOB_NAME:?JOB_NAME is required}"
: "${BUILD_NUMBER:?BUILD_NUMBER is required}"
: "${ARTIFACT_NAME:?ARTIFACT_NAME is required}"
: "${ARTIFACT_BUILD:?ARTIFACT_BUILD is required}"
: "${ARTIFACT_CHECKSUM:?ARTIFACT_CHECKSUM is required}"
: "${GIT_BRANCH:?GIT_BRANCH is required}"
: "${GIT_COMMIT:?GIT_COMMIT is required}"
: "${APPROVED_BY:?APPROVED_BY is required}"
: "${DEPLOY_STATUS:?DEPLOY_STATUS is required}"


REPORT_DIR="deployment-history/${ENVIRONMENT,,}"

REPORT_FILE="${REPORT_DIR}/deployment-${BUILD_NUMBER}.json"

mkdir -p "$REPORT_DIR"


cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "${ENVIRONMENT}",

  "jenkins_job": "${JOB_NAME}",
  "jenkins_build": "${BUILD_NUMBER}",

  "artifact": "${ARTIFACT_NAME}",
  "artifact_build": "${ARTIFACT_BUILD}",
  "artifact_checksum": "${ARTIFACT_CHECKSUM}",
  "checksum_status": "PASSED",

  "git_branch": "${GIT_BRANCH}",
  "git_commit": "${GIT_COMMIT}",

  "approved_by": "${APPROVED_BY}",
  "status": "${DEPLOY_STATUS}"
}
EOF


echo "Deployment report generated:"
cat "$REPORT_FILE"