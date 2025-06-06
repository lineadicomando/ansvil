> 🇮🇹 [Versione italiana](../it/access.md)

# Access and credentials

Once Ansvil is up and running, you can access the web interface via browser:

[https://127.0.0.1](https://127.0.0.1) or [https://localhost](https://localhost)

A **welcome page** will appear with direct links to:

* **Code-Server**
* **Semaphore UI**

## Access from other devices (LAN)

If the host is properly configured (hostname, firewall, local DNS), you can access it from your local network:

* via **local hostname** (e.g. `https://ansvil.local`)
* or via **private IP** (e.g. `https://192.168.1.42`)

In both cases, **as long as port `443` is reachable**, you're good to go.
No need to expose ports `8080` or `3000` directly.

## Default credentials

| Service          | User    | Password                   |
| ---------------- | ------- | -------------------------- |
| **Code-Server**  |         | `ansvil` *(password only)* |
| **Semaphore UI** | `admin` | `ansvil`                   |

You can change all initial credentials via the `.env` file.
