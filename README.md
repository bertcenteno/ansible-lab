# Ansible Lab

Production-style Ansible automation and CI/CD deployment lab built on Proxmox.

## Infrastructure

- Ubuntu 24.04 Ansible Control Node
- Ubuntu / Rocky Linux Managed Servers
- Jenkins CI/CD Server
- Proxmox Virtualization Platform

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
- Ansible Vault for secrets management
- Docker installation automation
- Docker container deployment using Ansible
- Environment-based inventory management
- DEV and PROD environment separation
- Jenkins Multibranch Pipeline integration
- Branch-based environment detection
- Automated DEV deployment workflow
- Production deployment approval gate
- CI/CD pipeline with Ansible syntax validation
- Automated deployment notifications via Microsoft Teams

## Repository Structure

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
- Automatic deployment
- No approval required
- Uses DEV variables and secrets

## Deployment Flow

Deployment is controlled by Git branches using Jenkins Multibranch Pipeline.

### DEV Deployment

```text
Push to develop branch
        |
        v
Jenkins Multibranch Pipeline
        |
        v
Detect Environment

Branch: develop
Environment: DEV

        |
        v
Ansible Syntax Validation
        |
        v
Deploy using DEV inventory
```

No approval required for DEV deployment.

---

## Branching Strategy

```text
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
```

### PROD Deployment

```text
Push to main branch
        |
        v
Jenkins Multibranch Pipeline
        |
        v
Detect Environment

Branch: main
Environment: PROD

        |
        v
Ansible Syntax Validation
        |
        v
Approval Gate
        |
        v
Deploy using PROD inventory
```

Production deployment requires manual approval before execution.

---

## Jenkins Pipeline Features

The Jenkins pipeline provides:

- GitHub SCM integration
- Parameterized deployment environment selection
- DEV / PROD inventory selection
- Ansible syntax validation
- Remote Ansible execution
- Ansible Vault password injection
- Production approval gate
- Microsoft Teams deployment notifications

## Deployment Commands

### DEV Deployment

```bash
ansible-playbook \
-i inventories/dev/hosts \
--vault-password-file .vault_pass \
site.yml
PROD Deployment
ansible-playbook \
-i inventories/prod/hosts \
--vault-password-file .vault_pass \
site.yml
CI/CD Deployment Flow
                 GitHub
                    |
                    v
                Jenkins
                    |
          +---------+---------+
          |                   |
         DEV                 PROD
          |                   |
 inventories/dev       inventories/prod
          |                   |
          +---------+---------+
                    |
                    v
          Ansible Control Node
                    |
                    v
              Managed Servers
Security
Secrets are managed using Ansible Vault
Vault passwords are injected securely during Jenkins execution
Production deployments require manual approval
Deployment activities are logged through Jenkins and Teams notifications

