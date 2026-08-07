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
- Idempotent playbooks
- Jinja2 templates
- Handlers
- Git feature branching
- Ansible Vault for secrets management
- Docker installation automation
- Docker container deployment
- Environment-based inventory management
- DEV and PROD environment separation
- Jenkins automated deployment pipeline

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

### DEV Deployment

```text
Git Push
    |
    v
Jenkins Pipeline
    |
    v
DEPLOY_ENV=DEV
    |
    v
Ansible Syntax Validation
    |
    v
Deploy using DEV inventory
```

No approval required.

---

### PROD Deployment

```text
Git Push
    |
    v
Jenkins Pipeline
    |
    v
DEPLOY_ENV=PROD
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

Production deployment requires manual approval.

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
Deployment activities are logged through Jenkins and Teams notifications.


####
TEST
