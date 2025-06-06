> 🇬🇧 [English version](../en/deployment.md)

# Deployment e porte

Ansvil utilizza `network_mode: host` per garantire che **Ansible** possa interagire direttamente con la rete dell'host, semplificando la comunicazione con dispositivi locali.

## Attenzione

- **Host dedicato consigliato** – Evita conflitti con altri servizi in ascolto sulle stesse porte.
- **Firewall obbligatorio** – Esponi solo le porte strettamente necessarie.
- **Sincronizzazione dell'orario (NTP)** – Fondamentale per TLS, logging, pianificazioni.

## Porte utilizzate

| Porta | Uso                        | Note |
|-------|-----------------------------|-------------------------------------------|
| `80`  | HTTP                        | Redirect automatico verso HTTPS (`443`)   |
| `443` | HTTPS (reverse proxy)       | **Unica porta da esporre per accesso web** |
| `8080`| Code-Server (interno)       | Accessibile solo tramite reverse proxy    |
| `3000`| Semaphore UI (interno)      | Accessibile solo tramite reverse proxy    |
| `3306`| MariaDB (interno)           | Accessibile solo dai container            |

**Esporre solo la porta `443`** all'esterno.
Tutte le altre porte sono utilizzate **solo all'interno del container** e gestite dal reverse proxy integrato (basato su Nginx).
