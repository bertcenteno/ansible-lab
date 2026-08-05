# Ansible Lab

Production-style Ansible automation lab built on Proxmox.

## Environment

- Ubuntu 24.04 Control Node
- Ubuntu Managed Server
- Rocky Linux Managed Server

## Roles

- Common
- Users
- Chrony
- Apache
- MariaDB

## Features

- Cross-platform support
- Idempotent playbooks
- Jinja2 templates
- Handlers
- Git feature branching
- Ansible Vault for secrets management
- Docker Role
- Docker Container Deployment

## Run

```bash
ansible-playbook site.yml
# Webhook test Wed Aug  5 08:22:42 AM UTC 2026
