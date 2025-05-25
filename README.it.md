[![Version](https://img.shields.io/badge/version-v0.1.0--beta-blue)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 🇬🇧 [English version](README.md)

# ANSVIL

**ANSVIL** – *Il villaggio containerizzato per l’automazione Ansible*

ANSVIL è un container Docker leggero e modulare basato su **AlmaLinux**, progettato per offrire un ambiente completo, stabile e portatile per l’automazione con **Ansible**.  
Include:

- **Ansible**
- **Code-Server** (VS Code via browser)
- **Semaphore UI** (interfaccia web per orchestrare task Ansible)

Che tu stia scrivendo playbook, orchestrando task o semplicemente cercando di sopravvivere all’indentazione dello YAML, **ANSVIL è il tuo spazio sicuro per l'automazione**.

---

## Contenuto del progetto

- **AlmaLinux 9.x** – base compatibile con RHEL, stabile e sicura  
- **Ansible** – cuore del sistema di automazione  
- **Code-Server** – Visual Studio Code accessibile via browser  
- **Semaphore UI** – frontend per il controllo dei task Ansible  

---

## Perché “villaggio”?

Il nome nasce da una metafora semplice:  
come in un villaggio ogni strumento ha il suo ruolo, in ANSVIL ogni componente è pensato per convivere armoniosamente con gli altri.  
Editing, orchestrazione, esecuzione e gestione: **tutto in un unico ecosistema coeso e modulare**.

---

## Considerazioni sul deployment

ANSVIL utilizza `network_mode: host` per garantire che **Ansible** possa interagire direttamente con la rete dell’host, semplificando la comunicazione con dispositivi locali.

### Attenzione

- **Host dedicato consigliato** – Evita conflitti con altri servizi in ascolto sulle stesse porte.  
- **Firewall obbligatorio** – Esponi solo le porte strettamente necessarie.  
- **Sincronizzazione dell’orario (NTP)** – Fondamentale per TLS, logging, pianificazioni.

---

### Porte utilizzate

| Porta | Uso                        | Note                                       |
|-------|-----------------------------|--------------------------------------------|
| `80`  | HTTP                        | Redirect automatico verso HTTPS (`443`)    |
| `443` | HTTPS (reverse proxy)       | **Unica porta da esporre per accesso web** |
| `8080`| Code-Server (interno)       | Accessibile solo tramite reverse proxy     |
| `3000`| Semaphore UI (interno)      | Accessibile solo tramite reverse proxy     |
| `3306`| MariaDB (interno)           | Accessibile solo dai container             |

**Esporre solo la porta `443`** all’esterno.  
Tutte le altre porte sono utilizzate **solo all’interno del container** e gestite dal reverse proxy integrato (basato su Nginx).

---

## Avvio rapido

### Metodo manuale (senza `make`)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
cp .env.example .env  # configura le variabili d’ambiente
docker compose up -d
````

### Metodo con `make` (consigliato)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
make init     # crea il file .env se non esiste
make up       # avvia i servizi in background
```

Per altri comandi disponibili:

```bash
make help
```

---

## Accesso ai servizi

Una volta avviato ANSVIL, puoi accedere all’interfaccia web tramite browser:

https://127.0.0.1 oppure https://localhost

Comparirà una **pagina di benvenuto** con collegamenti diretti a:

* **Code-Server**
* **Semaphore UI**

### Accesso da altri dispositivi (LAN)

Se l’host è configurato correttamente (hostname, firewall, DNS locale), puoi accedere anche dalla rete locale:

* tramite **hostname locale** (es. `https://ansvil.local`)
* oppure con **IP privato** (es. `https://192.168.1.42`)

In entrambi i casi, **basta che la porta `443` sia raggiungibile**.
Non è necessario esporre direttamente le porte `8080` o `3000`.

---

### Credenziali predefinite

| Servizio         | Utente       | Password                   |
| ---------------- | ------------ | -------------------------- |
| **Code-Server**  |              | `ansvil` *(solo password)* |
| **Semaphore UI** | `admin`      | `ansvil`                   |

Puoi modificare tutte le credenziali iniziali tramite il file `.env`.

---

## Hook di inizializzazione (`entrypoint.d/`)

ANSVIL supporta **hook modulari** eseguibili in fasi chiave del ciclo di vita dei container.

### Struttura delle directory

```
/entrypoint.d/
├── root/   → script eseguiti come utente root
└── user/   → script eseguiti come utente applicativo (es. ansvil)
```

### Eventi disponibili

| Evento  | Momento                        | Descrizione                              |
| ------- | ------------------------------ | ---------------------------------------- |
| `init`  | Solo al primo avvio            | Setup iniziale, installazioni, bootstrap |
| `start` | A ogni avvio del container     | Post-avvio, healthcheck, trigger custom  |
| `exit`  | Alla chiusura (SIGTERM/SIGINT) | Pulizia finale, salvataggi, notifiche    |

### Convenzione di naming

```
NN-<evento>-<descrizione>.sh
```

Esempi:

* `10-init-install-ansible.sh`
* `20-start-healthcheck.sh`
* `99-exit-cleanup.sh`

Gli script sono ordinati ed eseguiti in ordine crescente, per `root` e `user` separatamente.

### Inizializzazione automatica

Se le directory `entrypoint.d/root/` o `entrypoint.d/user/` mancano, ANSVIL copierà un template base da `/template/entrypoint.d/`.
Personalizzabile e montabile su `/data`.

### Esempio: hook user/init

```bash
#!/bin/bash
echo ">> [user/init] Installazione iniziale delle collection Ansible"

# ansible-galaxy collection install community.general
# pip install netaddr passlib
```

---

## Licenza e componenti open-source

ANSVIL è distribuito sotto licenza [MIT](LICENSE).
Utilizza o integra i seguenti componenti open-source:

| Componente   | Licenza    |
| ------------ | ---------- |
| Ansible      | GNU GPL v3 |
| Code-Server  | MIT        |
| Semaphore UI | MIT        |
| MariaDB      | GNU GPL v2 |
| Nginx        | BSD-like   |

Verifica le licenze ufficiali per un uso conforme, soprattutto in ambienti aziendali o in caso di ridistribuzione.