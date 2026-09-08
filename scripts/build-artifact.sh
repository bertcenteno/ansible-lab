#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO_ROOT"

GIT_COMMIT="$(git rev-parse --short HEAD)"
GIT_BRANCH="${BRANCH_NAME:-$(git branch --show-current)}"

BUILD_NUMBER="${BUILD_NUMBER:-manual}"

ARTIFACT_NAME="ansible-deployment-build-${BUILD_NUMBER}.tar.gz"
MANIFEST_NAME="ansible-deployment-build-${BUILD_NUMBER}.manifest.json"

WORK_DIR="$(mktemp -d)"
ARTIFACT_DIR="${WORK_DIR}/ansible-deployment"

cleanup() {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

echo "===== ARTIFACT BUILD ====="
echo "Repository : $REPO_ROOT"
echo "Branch     : $GIT_BRANCH"
echo "Commit     : $GIT_COMMIT"
echo "Build      : $BUILD_NUMBER"
echo "Artifact   : $ARTIFACT_NAME"
echo

mkdir -p "$ARTIFACT_DIR"

echo "===== COPYING DEPLOYMENT FILES ====="

cp ansible.cfg "$ARTIFACT_DIR/"
cp requirements.yml "$ARTIFACT_DIR/"
cp site.yml "$ARTIFACT_DIR/"

cp -a inventories "$ARTIFACT_DIR/"
cp -a roles "$ARTIFACT_DIR/"

echo "===== CREATING VERSION FILE ====="

cat > "$ARTIFACT_DIR/VERSION" <<EOF
BUILD_NUMBER=${BUILD_NUMBER}
GIT_COMMIT=${GIT_COMMIT}
GIT_BRANCH=${GIT_BRANCH}
EOF

echo "===== CREATING ARTIFACT ====="

tar -czf "$ARTIFACT_NAME" \
    -C "$WORK_DIR" \
    ansible-deployment

echo "===== GENERATING CHECKSUM ====="

sha256sum "$ARTIFACT_NAME" > "${ARTIFACT_NAME}.sha256"

echo "===== CREATING ARTIFACT MANIFEST ====="

ARTIFACT_CHECKSUM="$(awk '{print $1}' "${ARTIFACT_NAME}.sha256")"
JENKINS_JOB="${JOB_NAME:-manual}"

jq -n \
    --arg schema_version "1" \
    --arg artifact_name "$ARTIFACT_NAME" \
    --arg artifact_build "$BUILD_NUMBER" \
    --arg artifact_sha256 "$ARTIFACT_CHECKSUM" \
    --arg source_branch "$GIT_BRANCH" \
    --arg source_commit "$GIT_COMMIT" \
    --arg jenkins_job "$JENKINS_JOB" \
    --arg jenkins_build "$BUILD_NUMBER" \
    '{
        schema_version: $schema_version,
        artifact: {
            name: $artifact_name,
            build: $artifact_build,
            sha256: $artifact_sha256
        },
        source: {
            branch: $source_branch,
            commit: $source_commit
        },
        jenkins: {
            job: $jenkins_job,
            build: $jenkins_build
        }
    }' > "$MANIFEST_NAME"

jq empty "$MANIFEST_NAME"

echo
echo "===== ARTIFACT CREATED ====="

ls -lh \
    "$ARTIFACT_NAME" \
    "${ARTIFACT_NAME}.sha256" \
    "$MANIFEST_NAME"

echo
echo "===== CHECKSUM ====="

cat "${ARTIFACT_NAME}.sha256"

echo
echo "===== ARTIFACT MANIFEST ====="

cat "$MANIFEST_NAME"

echo
echo "===== ARTIFACT CONTENTS ====="

tar -tzf "$ARTIFACT_NAME"
