[![Version](https://img.shields.io/badge/version-v0.1.0--beta-blue)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 🇮🇹 [Versione in italiano](README.it.md).

# ANSVIL

**ANSVIL** – *The containerized village for Ansible automation*

ANSVIL is a lightweight and modular Docker container based on AlmaLinux, designed to provide a complete, stable, and portable automation environment for those working with Ansible.  
It includes **Ansible**, **Code-Server (VS Code via browser)**, and **Semaphore UI** in a preconfigured and easily customizable ecosystem.

Whether you're writing playbooks, orchestrating tasks, or simply trying to survive YAML indentation, ANSVIL is your safe space for automation.

---

## What’s inside

- **AlmaLinux 9.x** – a secure, stable, RHEL-compatible base system
- **Ansible** – the core engine for automation
- **Code-Server** – Visual Studio Code accessible via browser
- **Semaphore UI** – a web interface for managing and scheduling Ansible tasks

---

## Why “village”?

ANSVIL was conceived as a small specialized ecosystem where each tool has its place: orchestration, editing, execution, and management.  
A unified, coherent, and modular environment, built for those who live and work with Ansible every day.

---

## Deployment considerations

ANSVIL uses `network_mode: host` for all containers. This allows Ansible, running inside the container, to interact directly with the host network, accessing local devices and services without additional configuration.

However, this choice involves some important considerations:

- **Dedicated host**: the machine running ANSVIL should be reserved for this purpose. Avoid conflicts with other active services.
- **Used ports**:

  - `80` – HTTP (redirects to HTTPS)
  - `443` – HTTPS (reverse proxy)
  - `8080` – Code-server
  - `3000` – Semaphore UI
  - `3306` – MariaDB/MySQL database

- **Firewall required**: restrict port exposure to only those strictly necessary.
- **Time synchronization**: ensure the host uses NTP to avoid time-related issues (e.g., TLS certificate errors).

> **Security:** containers run with elevated privileges (no rootless mode or user namespace remapping). Maximum flexibility, but requires awareness.
>
> **Data persistence:** `./projects` for playbooks, `./data` for databases and configs. Customizable via environment variables. Make regular backups.

---

## Quick start

### Manual method (without `make`)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
cp .env.example .env  # configure environment variables
docker compose up -d
````

### Method with `make` (simpler)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
make init     # creates the .env file if it doesn't exist
make up       # starts services in background
```

To see available commands:

```bash
make help
```

---

## Initialization hooks (`entrypoint.d/`)

ANSVIL supports modular hooks that can be executed at three key points in the container lifecycle:

### Directory structure

```
/entrypoint.d/
├── root/   → scripts run as root user
└── user/   → scripts run as application user (e.g., ansvil)
```

### Available events

| Event   | Timing                                         | Description                                                |
| ------- | ---------------------------------------------- | ---------------------------------------------------------- |
| `init`  | Only on the container’s first start            | Initialization (e.g., installations, configuration, setup) |
| `start` | Every container start                          | After services start (e.g., triggers, healthchecks)        |
| `exit`  | When the container shuts down (SIGTERM/SIGINT) | Cleanup, saving, final notifications                       |

### Naming convention

```
NN-<event>-<description>.sh
```

Examples:

* `10-init-install-ansible.sh`
* `20-start-healthcheck.sh`
* `99-exit-cleanup.sh`

Scripts are executed in ascending order, separately for `root` and `user`.

### Automatic initialization

If the `/entrypoint.d/root/` or `/entrypoint.d/user/` directories do not exist, ANSVIL automatically copies a base template from `/template/entrypoint.d/`, ready to be customized and mounted into the `/data` volume.

### Example: user/init hook

```bash
#!/bin/bash
echo ">> [user/init] Initial installation of Ansible collections"

# ansible-galaxy collection install community.general
# pip install netaddr passlib
```

---

## License and open-source components

ANSVIL is released under the [MIT License](LICENSE).
It includes or connects to open-source software under separate licenses:

* **Ansible** – GNU GPL v3
* **Code-Server** – MIT
* **Semaphore UI** – MIT
* **MariaDB** – GNU GPL v2
* **Nginx** – BSD-like license

Check the official licenses of each component to ensure compliance, especially in corporate or redistribution contexts.