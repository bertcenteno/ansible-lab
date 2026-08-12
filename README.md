# Ansible Lab
Production-style Ansible automation and CI/CD deployment lab built on Proxmox.

## Infrastructure

- Ubuntu 24.04 Ansible Control Node
- Ubuntu / Rocky Linux Managed Servers
- Jenkins CI/CD Server
- Proxmox Virtualization Platform
- GitHub Repository

## Ansible Roles

- Common
- Users
- Chrony
- Apache
- MariaDB
- Docker
- Docker Compose

## Features

- Cross-platform support (Debian / RedHat based systems)
- Idempotent Ansible playbooks
- Jinja2 templates and configuration management
- Ansible handlers for service management
- Git-based feature branching workflow
- Pull Request validation workflow
- Ansible Vault for secrets management
- Docker installation automation
- Docker container deployment using Ansible
- Post-deployment Docker Compose service verification
- Docker container health verification
- Post-deployment HTTP application verification
- Deployment failure protection for unhealthy services
- Environment-based inventory management
- DEV and PROD environment separation
- Dedicated DEV and PROD Docker hosts
- Environment-specific application variables and Vault secrets
- Controlled DEV-to-PROD promotion workflow
- Jenkins Multibranch Pipeline integration
- Branch-based environment detection
- Automated DEV deployment workflow
- Production deployment approval gate
- Manual approval enforcement before PROD deployment
- Docker Compose health verification with retry and wait handling
- Docker engine and application deployment responsibility separation
- CI/CD pipeline with YAML lint validation
- CI/CD pipeline with Ansible lint validation
- Ansible syntax validation before deployment
- Automated Ansible dependency installation
- Automated deployment notifications via Microsoft Teams
- Automated PR validation before merge
- Automated DEV deployment after merge
- Reusable Jenkins pipeline helper closure for Ansible execution
- Reliable Jenkins Vault secret cleanup using shell EXIT traps
- Explicit Ansible exit code handling with contextual pipeline errors
- Separation of Pull Request validation and deployment stages
- Consistent CI virtual environment for PR validation
- Environment-aware Microsoft Teams validation and deployment notifications
- CI failure protection for YAML and Ansible lint violations

---

# Repository Structure

```text
ansible-lab/
│
├── inventories/
│   ├── dev/
│   │   ├── hosts
│   │   └── group_vars/
│   │       ├── all/
│   │       │   └── vault.yml
│   │       └── dockerhosts.yml
│   │
│   └── prod/
│       ├── hosts
│       └── group_vars/
│           ├── all/
│           │   └── vault.yml
│           └── dockerhosts.yml
│
├── roles/
│   ├── common/
│   ├── users/
│   ├── chrony/
│   ├── apache/
│   ├── mariadb/
│   ├── docker/
│   └── docker_compose/
│
├── requirements.yml
├── site.yml
├── Jenkinsfile
└── README.md
```
## Environment Management

Separate inventories are maintained for DEV and PROD environments.

### DEV Environment

Inventory:

inventories/dev/hosts

Features:

- Managed host: `docker01`
- Automatic deployment
- No approval required
- Uses DEV variables and Vault secrets
- Deployment triggered automatically after changes are merged into `develop`

### PROD Environment

Inventory:

inventories/prod/hosts

Features:

- Managed host: `docker-prod`
- Production deployment
- Manual approval required
- Uses PROD variables and Vault secrets
- Deployment triggered after changes are promoted to `main`

## Branching Strategy

The `develop` and `main` branches are permanent branches in the deployment workflow. Release branches are temporary branches used to stabilize and validate release candidates before production promotion.

- `feature/*` branches contain individual changes.
- `develop` represents the DEV environment and triggers automatic DEV deployment.
- `release/*` branches represent release candidates and perform validation without deployment.
- `main` represents the PROD environment and triggers the production deployment workflow.
- Changes are promoted through Pull Requests between protected branches.
- Completed releases are permanently identified using Git tags.

The repository uses a feature → develop → release → main workflow.

```text
feature/*
    |
    | Pull Request
    v
develop
    |
    | Automatic DEV Deployment
    v
docker01
    |
    | Pull Request
    v
release/vX.Y
    |
    | Release Candidate Validation
    | No Deployment
    v
Release Candidate
    |
    | Pull Request
    v
main
    |
    | Manual Approval Gate
    v
docker-prod
    |
    v
Production Release
    |
    +-- Tag vX.Y
    |
    +-- Retire release/vX.Y
```

### Feature Branches

Development work is performed using feature branches.

Example:

feature/v1.7-jenkinsfile-refactor

Changes are submitted through a Pull Request targeting the develop branch.


### CI/CD Pipeline

The Jenkins Multibranch Pipeline automatically discovers branches and Pull Requests from GitHub.

### Pull Request Validation

When a Pull Request is created or updated, GitHub triggers Jenkins through a webhook.

The PR validation workflow performs:

GitHub Pull Request
        |
        v
Jenkins Multibranch Pipeline
        |
        v
Checkout SCM
        |
        v
Install CI Dependencies
        |
        v
YAML Lint
        |
        v
Ansible Lint
        |
        v
PR Syntax Validation
(.ci-venv)
        |
        v
PASS
        |
        v
GitHub Check: Green

Pull Request validation is isolated from deployment operations. PR builds do not synchronize files to the Ansible controller, install dependencies on the controller, request deployment approval, or execute a deployment.

The purpose of the PR pipeline is to verify that the proposed changes meet the repository's validation requirements before they are merged.

### GitHub Webhook

GitHub webhooks are used to automatically trigger Jenkins when repository events occur.

The webhook is configured to send:

Push events
Pull Request events

This allows Jenkins to automatically validate Pull Requests without requiring a manual repository scan.

### DEV Deployment

After a Pull Request is successfully validated and merged into develop, Jenkins automatically starts the DEV deployment pipeline.

Pull Request
     |
     v
PR Validation
     |
     v
Merge into develop
     |
     v
GitHub Webhook
     |
     v
Jenkins Multibranch Pipeline
     |
     v
Detect Environment
     |
     v
DEV
     |
     v
Ansible Deployment
     |
     v
Managed Servers

No approval is required for DEV deployments.

Branch deployment order:

Sync Repository to Ansible Controller
        |
        v
Install Ansible Dependencies
        |
        v
Validate Ansible Syntax
        |
        v
Run Ansible Playbook


## PROD Deployment

```text
Feature Branch
      |
      v
Pull Request
      |
      v
PR Validation
      |
      v
develop
      |
      v
Automatic DEV Deployment
      |
      v
DEV Verification
      |
      v
Pull Request
develop -> release/vX.Y
      |
      v
Release Validation
      |
      v
Release Candidate
      |
      v
Pull Request
release/vX.Y -> main
      |
      v
PR Validation
      |
      v
Merge into main
      |
      v
Jenkins PROD Pipeline
      |
      v
Manual Approval Gate
      |
      v
PROD Deployment
      |
      v
Post-Deployment Verification
      |
      v
Deployment Successful
      |
      v
Tag Production Commit
      |
      v
Retire Release Branch
```

Production changes are tested through the DEV workflow and validated as a release candidate before being promoted to `main`.

The PROD deployment does not execute until the Jenkins manual approval gate is approved.

The production workflow was verified using the dedicated `docker-prod` managed host.

Release branches do not deploy infrastructure. They provide a dedicated validation stage between DEV and PROD.

After a successful production deployment, the production commit on `main` is tagged with the release version. The completed release branch can then be retired.

### Jenkins Pipeline Features

The Jenkins pipeline provides:

GitHub SCM integration
Jenkins Multibranch Pipeline
Automatic branch discovery
Pull Request discovery
GitHub webhook integration
Branch-based environment detection
DEV / PROD inventory selection
CI dependency installation
YAML lint validation
Ansible lint validation
Ansible syntax validation
Pull Request validation
Remote Ansible execution
Ansible Vault password injection
Reusable Jenkins pipeline helper closure
Production approval gate
Microsoft Teams deployment notifications
PR and deployment stage separation
Branch-only Ansible controller synchronization
Contextual Ansible execution error handling
Reliable local and remote Vault password cleanup
Environment-aware validation and deployment notifications
Post-deployment Docker Compose health verification
Post-deployment HTTP application verification
Deployment failure on failed post-deployment verification
Release branch discovery
Release candidate validation
Release-only validation without deployment
Protected develop / release / main promotion workflow

### Jenkins Ansible Execution

The Jenkinsfile uses a reusable helper closure for Ansible execution.

The helper handles:

Ansible controller authentication
Vault password transfer
Ansible playbook execution
Inventory selection
Additional Ansible arguments
Local Vault password cleanup using an EXIT trap
Remote Vault password cleanup using an EXIT trap
Ansible exit code capture
Contextual Jenkins error reporting

Vault password cleanup is executed even when Ansible execution fails.

This reduces duplicated Jenkins pipeline code between DEV and PROD deployment stages.

### Deployment Verification

After Docker Compose projects are deployed, Ansible performs post-deployment verification before the Jenkins deployment is considered successful.

The verification workflow checks:

Docker Compose service status
nginx container running state
nginx container health status
MariaDB container running state
MariaDB container health status
nginx HTTP application response

### Container Verification

Docker Compose service information is collected using:

docker compose ps --format json

Ansible verifies that required containers report:

State: running
Health: healthy

The following services are currently verified:

nginx
mariadb

If a required service is not running or does not report a healthy status, the Ansible playbook fails and Jenkins marks the deployment as failed.

Container health verification includes retry and delay handling.

This allows newly started containers to transition through temporary states such as:

```text
State: running
Health: starting
```

HTTP Application Verification

After container health verification succeeds, Ansible performs an HTTP request against:

http://localhost:8080

The nginx application must return:

HTTP 200

The HTTP verification includes retry handling to allow the application time to become available.

Deployment Verification Flow

Docker Compose Deployment
        |
        v
Check Service Status
        |
        +------ nginx ------> running + healthy
        |
        +------ mariadb ----> running + healthy
        |
        v
nginx HTTP Verification
        |
        v
HTTP 200
        |
        v
Deployment Successful

If any verification step fails:

Verification Failure
        |
        v
Ansible Playbook Failure
        |
        v
Non-Zero Exit Code
        |
        v
Jenkins Deployment Failed
        |
        v
Microsoft Teams Failure Notification

### Automatic Deployment Rollback

The `docker_compose` role protects the deployed applications using a last known-good configuration.

Verified Docker Compose configurations are stored on the managed Docker host under:

```text
/opt/compose/.known-good/
```

Each Docker Compose project maintains its own known-good configuration:

```text
/opt/compose/.known-good/nginx/docker-compose.yml
/opt/compose/.known-good/mariadb/docker-compose.yml
/opt/compose/.known-good/portainer/docker-compose.yml
```

After a deployment passes container and HTTP verification, the active Compose files are promoted to the known-good state.

If deployment or verification fails, the Ansible rescue workflow:

1. Detects the deployment failure.
2. Restores the last known-good Compose files.
3. Redeploys the known-good Docker Compose projects.
4. Verifies the restored service state.
5. Verifies the nginx HTTP response.
6. Records successful rollback status for Jenkins.

```text
Docker Compose Deployment
        |
        v
Deployment Verification
        |
   +----+----+
   |         |
 PASS       FAIL
   |         |
   v         v
Promote    Ansible Rescue
to         |
Known-Good v
           Restore Known-Good
           Compose Files
                |
                v
           Redeploy Services
                |
                v
           Verify Containers
                |
                v
           Verify nginx HTTP 200
                |
                v
           Rollback Successful
```

A successful rollback does not convert the failed deployment into a successful Jenkins build. The original deployment remains failed while Jenkins records that service recovery completed successfully.

Microsoft Teams failure notifications report the rollback result as:

```text
Rollback: SUCCESSFUL - Last known-good configuration restored
```

This allows the pipeline to distinguish between a failed deployment where service recovery succeeded and a deployment failure where no rollback was required.

## Docker Role Architecture

Docker infrastructure provisioning and application deployment are separated between two Ansible roles.

### Docker Role

The `docker` role is responsible for:

- Configuring the Docker CE repository
- Installing Docker Engine
- Installing Docker Compose
- Starting and enabling the Docker service
- Configuring Docker group membership
- Installing required Docker Python dependencies
- Removing the legacy standalone nginx container

### Docker Compose Role

The `docker_compose` role is responsible for application deployment:

- nginx
- MariaDB
- Portainer
- Docker Compose project deployment
- Container running-state verification
- Container health verification
- nginx HTTP verification

This separation prevents the Docker infrastructure role from independently deploying application containers.

During v2.0, the previous standalone nginx container on port `80` was removed from both DEV and PROD. The Compose-managed nginx service remains available on port `8080`.

Final nginx ownership:

```text
docker role
    |
    +-- Docker Engine provisioning
    |
    +-- Legacy nginx cleanup

docker_compose role
    |
    +-- nginx :8080
    +-- MariaDB
    +-- Portainer
    +-- Health verification
```

## Deployment Commands
DEV Deployment
ansible-playbook \
-i inventories/dev/hosts \
--vault-password-file .vault_pass \
site.yml
PROD Deployment
ansible-playbook \
-i inventories/prod/hosts \
--vault-password-file .vault_pass \
site.yml
Ansible Syntax Validation
ansible-playbook \
-i inventories/dev/hosts \
--syntax-check \
site.yml

## CI/CD Deployment Flow

```text
                    Feature Branch
                          |
                          v
                    Pull Request
                          |
                          v
                  Jenkins Validation
                          |
               +----------+----------+
               |          |          |
           YAML Lint  Ansible Lint  Syntax
               |          |          |
               +----------+----------+
                          |
                          v
                       develop
                          |
                          v
                Automatic DEV Deploy
                          |
                          v
                       docker01
                          |
                          v
                Deployment Verification
                          |
                          v
                    DEV Successful
                          |
                          v
               Pull Request to release
                          |
                          v
                    release/vX.Y
                          |
                          v
                 Release Validation
                          |
                          v
                  Release Candidate
                          |
                          v
                 Pull Request to main
                          |
                          v
                  Jenkins Validation
                          |
                          v
                         main
                          |
                          v
                 Manual Approval Gate
                          |
                          v
                 Automatic PROD Deploy
                          |
                          v
                     docker-prod
                          |
                          v
                Deployment Verification
                          |
               +----------+----------+
               |                     |
          Container Health       HTTP 200
               |                     |
               +----------+----------+
                          |
                          v
                   PROD Successful
                          |
                          v
                       Tag vX.Y
                          |
                          v
                 Retire Release Branch
```

## Security

Secrets are managed using Ansible Vault.

Vault passwords are injected securely during Jenkins execution
Vault password files are removed after deployment
Sensitive variables are stored in encrypted Vault files
Production deployments require manual approval
Deployment activities are logged through Jenkins and Teams notifications

## Version History

### v2.2

Automatic deployment rollback and rollback observability:

- Added last known-good Docker Compose configuration management
- Added automatic promotion of verified Compose configurations to known-good state
- Added Ansible rescue workflow for failed Docker Compose deployments
- Added automatic restoration and redeployment of known-good configurations
- Added post-rollback container state verification
- Added post-rollback nginx HTTP verification
- Added Jenkins rollback status propagation
- Added dedicated rollback exit-code handling between Ansible and Jenkins
- Added Microsoft Teams rollback status reporting
- Verified failed deployment remains failed after successful service recovery
- Verified successful rollback restores `nginx:1.31.3`
- Verified restored nginx container reports `running` and `healthy`
- Verified restored nginx application returns HTTP 200
- Verified active Compose files match the saved known-good configurations after rollback
- Verified successful recovery deployment after restoring the valid nginx image
- Verified recovery deployment is idempotent with `changed=0`, `failed=0`, and `rescued=0`

### v2.1

Release branch workflow and protected promotion lifecycle:

- Added support for `release/*` branches in the Jenkins Multibranch Pipeline
- Added dedicated `RELEASE` pipeline type
- Added release candidate validation using the `VALIDATION` environment
- Added dedicated Release Validation stage
- Release branches perform YAML lint, Ansible lint, and Ansible syntax validation without deployment
- Implemented `develop` → `release/*` → `main` promotion workflow
- Verified feature → Pull Request → develop → DEV deployment workflow
- Verified develop → release Pull Request validation
- Verified successful `release/v2.1` release candidate validation
- Verified release → main Pull Request validation
- Verified manual approval before production deployment
- Verified successful v2.1 production deployment to `docker-prod`
- Added branch protection for `develop`, `release/*`, and `main`
- Verified direct pushes are rejected on protected branches
- Verified protected release branches cannot be deleted without authorized ruleset changes
- Added annotated production release tag `v2.1`
- Verified `v2.1` tag points to the production commit on `main`
- Added completed release branch retirement workflow
- Verified `main`, `release/v2.1`, and `develop` contained identical release content after promotion
- Completed end-to-end feature → develop → DEV → release → validation → main → approval → PROD → tag workflow

### v2.0

Production workflow and environment separation:

- Added dedicated PROD Docker host
- Separated DEV and PROD managed infrastructure
- Added environment-specific DEV and PROD inventories
- Added environment-specific application variables and Vault secrets
- Implemented `develop` → `main` production promotion workflow
- Verified Pull Request validation before production promotion
- Verified automatic DEV deployment from `develop`
- Verified manual approval gate before PROD deployment
- Verified production deployment from `main`
- Improved Docker Compose health verification with retry and delay handling
- Added wait handling for containers transitioning through `health: starting`
- Verified deployment failure when container health verification fails
- Verified successful deployment after health-check retry refinement
- Separated Docker engine provisioning from application deployment
- Removed legacy standalone nginx deployment
- Migrated nginx application ownership to Docker Compose
- Verified legacy nginx cleanup in DEV and PROD
- Verified DEV deployment idempotency
- Verified nginx and MariaDB container health in PROD
- Verified nginx HTTP 200 response after PROD deployment
- Completed end-to-end feature → develop → DEV → main → approval → PROD workflow

### v1.9

Deployment verification improvements:

- Added post-deployment Docker Compose service verification
- Added running-state verification for nginx and MariaDB
- Added container health verification for nginx and MariaDB
- Added nginx HTTP 200 post-deployment verification
- Added retry handling for HTTP application verification
- Added deployment failure protection for unhealthy Docker Compose services
- Added deployment failure protection for failed HTTP verification
- Verified container health failure detection
- Verified successful Pull Request validation
- Verified PR merge → develop → DEV deployment with post-deployment verification

### v1.8

Pipeline quality and reliability improvements:

Added reliable local Jenkins Vault password cleanup using EXIT traps
Added reliable remote Ansible controller Vault password cleanup using EXIT traps
Added explicit Ansible exit code handling
Added contextual pipeline error messages with environment, inventory, arguments, and exit code
Separated Pull Request validation from controller and deployment stages
Restricted Ansible controller synchronization and dependency installation to branch pipelines
Reordered branch deployment to sync repository before remote syntax validation
Standardized PR validation on the CI virtual environment
Added environment-aware Microsoft Teams notification titles
Added separate validation and deployment success/failure notifications
Verified YAML lint failure protection
Verified Ansible lint failure protection
Verified Ansible execution failure handling
Verified successful PR validation → merge → develop → DEV deployment workflow

### v1.7

Jenkins CI/CD pipeline improvements:

Refactored Jenkins Ansible execution logic
Added reusable Jenkins pipeline helper closure
Added YAML lint validation
Added Ansible lint validation
Added Pull Request validation workflow
Added GitHub Pull Request webhook automation
Enabled automatic PR validation on changes
Verified automatic DEV deployment after merging into develop

### v1.6
Added CI validation pipeline
Added Jenkins validation workflow
Added YAML and Ansible validation preparation
Improved Jenkins Multibranch Pipeline workflow
