> 🇮🇹 [Versione italiana](../it/deployment.md)

# Deployment and ports

Ansvil uses `network_mode: host` to ensure that **Ansible** can interact directly with the host's network, simplifying communication with local devices.

## Warning

- **Dedicated host recommended** – Avoid conflicts with other services listening on the same ports.
- **Firewall is a must** – Expose only strictly necessary ports.
- **Time sync (NTP)** – Crucial for TLS, logging, and scheduling.

## Ports used

| Port  | Purpose                     | Notes |
|-------|-----------------------------|----------------------------------------------|
| `80`  | HTTP                        | Automatically redirects to HTTPS (`443`)      |
| `443` | HTTPS (reverse proxy)       | **Only port to expose for web access**        |
| `8080`| Code-Server (internal)      | Accessible only via reverse proxy            |
| `3000`| Semaphore UI (internal)     | Accessible only via reverse proxy            |
| `3306`| MariaDB (internal)          | Accessible only from containers              |

**Only expose port `443`** externally.
All other ports are used **internally within the container** and managed by the integrated reverse proxy (Nginx-based).
