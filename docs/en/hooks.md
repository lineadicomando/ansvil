> 🇮🇹 [Versione italiana](../it/hooks.md)

# Initialization hooks (`entrypoint.d/`)

Ansvil supports **modular hooks** that run at key points in the container lifecycle.

## Directory structure

```
/entrypoint.d/
├── root/   → scripts run as root
└── user/   → scripts run as app user (e.g. ansvil)
```

## Available events

| Event   | When it runs                           | Description |
| ------- | -------------------------------------- | --------------------------- |
| `init`  | First launch only (container creation) | Initial setup, installation, bootstrap |
| `start` | On every container start               | Post-start, health checks, custom triggers |
| `exit`  | On shutdown (SIGTERM/SIGINT)           | Final cleanup, save tasks, notifications |

## Naming convention

```
NN-<event>-<description>.sh
```

Examples:

* `10-init-install-ansible.sh`
* `20-start-healthcheck.sh`
* `99-exit-cleanup.sh`

Scripts are sorted and executed in ascending order, separately for `root` and `user`.

## Automatic initialization

If the `entrypoint.d/root/` or `entrypoint.d/user/` directories are missing, Ansvil will copy a default template from `/template/entrypoint.d/`.
This is customizable and can be mounted at `/data`.

## Example: user/init hook

```bash
#!/bin/bash
echo ">> [user/init] Initial installation of Ansible collections"

# ansible-galaxy collection install community.general
# pip install netaddr passlib
```
