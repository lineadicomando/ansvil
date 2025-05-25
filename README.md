[![Version](https://img.shields.io/badge/version-v0.1.0--beta-blue)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 🇮🇹 [Versione italiana](README.it.md)

# ANSVIL

**ANSVIL** – *The containerized village for Ansible automation*

ANSVIL is a lightweight and modular Docker container based on **AlmaLinux**, designed to provide a complete, stable, and portable environment for **Ansible** automation.  
It includes:

- **Ansible**
- **Code-Server** (VS Code via browser)
- **Semaphore UI** (web interface for orchestrating Ansible tasks)

Whether you're writing playbooks, orchestrating tasks, or just trying to survive YAML indentation, **ANSVIL is your safe space for automation**.

---

## Project contents

- **AlmaLinux 9.x** – a RHEL-compatible, stable and secure base  
- **Ansible** – the core automation engine  
- **Code-Server** – browser-accessible Visual Studio Code  
- **Semaphore UI** – frontend to manage Ansible tasks  

---

## Why “village”?

The name comes from a simple metaphor:  
just like every tool has its place in a village, in ANSVIL each component is designed to coexist harmoniously with the others.  
Editing, orchestration, execution, and management: **all in a single cohesive and modular ecosystem**.

---

## Deployment considerations

ANSVIL uses `network_mode: host` to ensure that **Ansible** can interact directly with the host's network, simplifying communication with local devices.

### Warning

- **Dedicated host recommended** – Avoid conflicts with other services listening on the same ports.  
- **Firewall is a must** – Expose only strictly necessary ports.  
- **Time sync (NTP)** – Crucial for TLS, logging, and scheduling.

---

### Ports used

| Port  | Purpose                     | Notes                                        |
|-------|-----------------------------|----------------------------------------------|
| `80`  | HTTP                        | Automatically redirects to HTTPS (`443`)     |
| `443` | HTTPS (reverse proxy)       | **Only port to expose for web access**       |
| `8080`| Code-Server (internal)      | Accessible only via reverse proxy            |
| `3000`| Semaphore UI (internal)     | Accessible only via reverse proxy            |
| `3306`| MariaDB (internal)          | Accessible only from containers              |

**Only expose port `443`** externally.  
All other ports are used **internally within the container** and managed by the integrated reverse proxy (Nginx-based).

---

## Quick start

### Manual method (without `make`)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
cp .env.example .env  # configure environment variables
docker compose up -d
````

### `make` method (recommended)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
make init     # creates .env file if missing
make up       # starts services in background
```

For more available commands:

```bash
make help
```

---

## Accessing the services

Once ANSVIL is up and running, you can access the web interface via browser:

[https://127.0.0.1](https://127.0.0.1) or [https://localhost](https://localhost)

A **welcome page** will appear with direct links to:

* **Code-Server**
* **Semaphore UI**

### Access from other devices (LAN)

If the host is properly configured (hostname, firewall, local DNS), you can access it from your local network:

* via **local hostname** (e.g. `https://ansvil.local`)
* or via **private IP** (e.g. `https://192.168.1.42`)

In both cases, **as long as port `443` is reachable**, you're good to go.
No need to expose ports `8080` or `3000` directly.

---

### Default credentials

| Service          | User    | Password                   |
| ---------------- | ------- | -------------------------- |
| **Code-Server**  |         | `ansvil` *(password only)* |
| **Semaphore UI** | `admin` | `ansvil`                   |

You can change all initial credentials via the `.env` file.

---

## Initialization hooks (`entrypoint.d/`)

ANSVIL supports **modular hooks** that run at key points in the container lifecycle.

### Directory structure

```
/entrypoint.d/
├── root/   → scripts run as root
└── user/   → scripts run as app user (e.g. ansvil)
```

### Available events

| Event   | When it runs                 | Description                                |
| ------- | ---------------------------- | ------------------------------------------ |
| `init`  | First launch only            | Initial setup, installation, bootstrap     |
| `start` | On every container start     | Post-start, health checks, custom triggers |
| `exit`  | On shutdown (SIGTERM/SIGINT) | Final cleanup, save tasks, notifications   |

### Naming convention

```
NN-<event>-<description>.sh
```

Examples:

* `10-init-install-ansible.sh`
* `20-start-healthcheck.sh`
* `99-exit-cleanup.sh`

Scripts are sorted and executed in ascending order, separately for `root` and `user`.

### Automatic initialization

If the `entrypoint.d/root/` or `entrypoint.d/user/` directories are missing, ANSVIL will copy a default template from `/template/entrypoint.d/`.
This is customizable and can be mounted at `/data`.

### Example: user/init hook

```bash
#!/bin/bash
echo ">> [user/init] Initial installation of Ansible collections"

# ansible-galaxy collection install community.general
# pip install netaddr passlib
```

---

## License and open-source components

ANSVIL is released under the [MIT](LICENSE) license.
It uses or integrates the following open-source components:

| Component    | License    |
| ------------ | ---------- |
| Ansible      | GNU GPL v3 |
| Code-Server  | MIT        |
| Semaphore UI | MIT        |
| MariaDB      | GNU GPL v2 |
| Nginx        | BSD-like   |

Check official licenses for compliance, especially in enterprise environments or when redistributing.