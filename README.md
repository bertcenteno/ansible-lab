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
PR Validation
        |
        v
Ansible Syntax Validation
        |
        v
PASS

Pull Request validation does not deploy to any environment.

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
Jenkins Ansible Execution

The Jenkinsfile uses a reusable helper closure for Ansible execution.

The helper handles:

Ansible controller authentication
Vault password transfer
Ansible playbook execution
Inventory selection
Additional Ansible arguments
Vault password cleanup

This reduces duplicated Jenkins pipeline code between DEV and PROD deployment stages.

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


