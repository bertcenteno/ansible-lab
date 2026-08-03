# Ansible Lab

Production-style Ansible automation lab built on Proxmox.

## Environment

- Ubuntu 24.04 Control Node (soon)
- Ubuntu Managed Server
- Rocky Linux Managed Server

## Roles

- Common
- Users
- Chrony
- Apache
- MariaDB (In Progress)

## Features

- Cross-platform support
- Idempotent playbooks
- Jinja2 templates
- Handlers
- Git feature branching

## Run

```bash
ansible-playbook site.yml
