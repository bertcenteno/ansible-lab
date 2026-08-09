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
- Jenkins Multibranch Pipeline integration
- Branch-based environment detection
- Automated DEV deployment workflow
- Production deployment approval gate
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

Environment Management

Separate inventories are maintained for DEV and PROD environments.

DEV Environment

Inventory:

inventories/dev/hosts

Features:

Automatic deployment
No approval required
Uses DEV variables and secrets
Deployment triggered automatically after changes are merged into develop

PROD Environment

Inventory:

inventories/prod/hosts

Features:

Production deployment
Manual approval required
Uses PROD variables and secrets
Deployment triggered from the main branch

Branching Strategy

The repository uses a feature branch → Pull Request → develop → main workflow.

feature/*
    |
    | Pull Request
    v
develop
    |
    | DEV Deployment
    |
    | Pull Request
    v
main
    |
    | Approval Gate
    v
PROD Deployment

Feature Branches

Development work is performed using feature branches.

Example:

feature/v1.7-jenkinsfile-refactor

Changes are submitted through a Pull Request targeting the develop branch.


CI/CD Pipeline

The Jenkins Multibranch Pipeline automatically discovers branches and Pull Requests from GitHub.

Pull Request Validation

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

GitHub Webhook

GitHub webhooks are used to automatically trigger Jenkins when repository events occur.

The webhook is configured to send:

Push events
Pull Request events

This allows Jenkins to automatically validate Pull Requests without requiring a manual repository scan.

DEV Deployment

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


PROD Deployment

Production deployments are triggered from the main branch.

Pull Request
     |
     v
develop
     |
     v
Validation
     |
     v
Merge into main
     |
     v
Jenkins Multibranch Pipeline
     |
     v
Detect Environment
     |
     v
Approval Gate
     |
     v
PROD Deployment

Production deployment requires manual approval before the Ansible playbook is executed.

Jenkins Pipeline Features

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

Jenkins Ansible Execution

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

Deployment Verification

After Docker Compose projects are deployed, Ansible performs post-deployment verification before the Jenkins deployment is considered successful.

The verification workflow checks:

Docker Compose service status
nginx container running state
nginx container health status
MariaDB container running state
MariaDB container health status
nginx HTTP application response

Container Verification

Docker Compose service information is collected using:

docker compose ps --format json

Ansible verifies that required containers report:

State: running
Health: healthy

The following services are currently verified:

nginx
mariadb

If a required service is not running or does not report a healthy status, the Ansible playbook fails and Jenkins marks the deployment as failed.

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

Deployment Commands
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
CI/CD Deployment Flow
                         GitHub
                            |
                +-----------+-----------+
                |                       |
             Push Event           Pull Request
                |                       |
                v                       v
             Jenkins              PR Validation
                |                       |
                |                 +-----+-----+
                |                 |           |
                |              YAML Lint   Ansible Lint
                |                 |           |
                |                 +-----+-----+
                |                       |
                |                 Syntax Check
                |                       |
                |                    PASS
                |                       |
                |                  Merge to develop
                |                       |
                +-----------+-----------+
                            |
                            v
                    Detect Environment
                            |
                     +------+------+
                     |             |
                    DEV           PROD
                     |             |
              Auto Deployment   Approval
                     |             |
              inventories/dev  inventories/prod
                     |             |
                     +------+------+
                            |
                            v
                   Ansible Control Node
                            |
                            v
                    Managed Servers
Security

Secrets are managed using Ansible Vault.

Vault passwords are injected securely during Jenkins execution
Vault password files are removed after deployment
Sensitive variables are stored in encrypted Vault files
Production deployments require manual approval
Deployment activities are logged through Jenkins and Teams notifications
Version History

v1.9

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

v1.8

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

v1.7

Jenkins CI/CD pipeline improvements:

Refactored Jenkins Ansible execution logic
Added reusable Jenkins pipeline helper closure
Added YAML lint validation
Added Ansible lint validation
Added Pull Request validation workflow
Added GitHub Pull Request webhook automation
Enabled automatic PR validation on changes
Verified automatic DEV deployment after merging into develop
v1.6
Added CI validation pipeline
Added Jenkins validation workflow
Added YAML and Ansible validation preparation
Improved Jenkins Multibranch Pipeline workflow


