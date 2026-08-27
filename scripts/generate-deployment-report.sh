#!/bin/bash

set -e

REPORT_DIR="deployment-history/${ENVIRONMENT,,}"

REPORT_FILE="${REPORT_DIR}/deployment-${BUILD_NUMBER}.json"

mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "${ENVIRONMENT}",
  "artifact": "${ARTIFACT_NAME}",
  "artifact_build": "${BUILD_NUMBER}",
  "git_branch": "${GIT_BRANCH}",
  "git_commit": "${GIT_COMMIT}",
  "approved_by": "${APPROVED_BY}",
  "status": "${DEPLOY_STATUS}"
}
EOF

echo "Deployment report generated:"
cat "$REPORT_FILE"
