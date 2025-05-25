# ANSVIL

**ANSVIL** – *Il villaggio containerizzato per l’automazione Ansible*

ANSVIL è un container Docker leggero e modulare basato su AlmaLinux, progettato per offrire un ambiente di automazione completo, stabile e portatile per chi lavora con Ansible.  
Include **Ansible**, **Code-Server (VS Code via browser)** e **Semaphore UI** in un ecosistema preconfigurato e facilmente personalizzabile.

Che tu stia scrivendo playbook, orchestrando task o semplicemente cercando di sopravvivere all’indentazione dello YAML, ANSVIL è il tuo spazio sicuro per l'automazione.

---

## Cosa contiene

- **AlmaLinux 9.x** – sistema base sicuro, stabile e compatibile con RHEL
- **Ansible** – motore centrale per l’automazione
- **Code-Server** – Visual Studio Code accessibile via browser
- **Semaphore UI** – interfaccia web per gestire e pianificare i task Ansible

---

## Perché “villaggio”?

ANSVIL nasce come un piccolo ecosistema specializzato dove ogni strumento ha il suo posto: orchestrazione, editing, esecuzione, gestione.  
Un ambiente unitario, coerente e modulare, pensato per chi vive e lavora quotidianamente con Ansible.

---

## Considerazioni per il deployment

ANSVIL utilizza `network_mode: host` per tutti i container. Questo consente ad Ansible, eseguito all’interno del container, di interagire direttamente con la rete dell’host, raggiungendo dispositivi e servizi locali senza configurazioni extra.

Tuttavia, questa scelta comporta alcune considerazioni importanti:

- **Host dedicato**: la macchina che esegue ANSVIL dovrebbe essere riservata a questo scopo. Evita conflitti con altri servizi attivi.
- **Porte utilizzate**:

  - `80` – HTTP (redirect verso HTTPS)
  - `443` – HTTPS (reverse proxy)
  - `8080` – Code-server
  - `3000` – Semaphore UI
  - `3306` – Database MariaDB/MySQL

- **Firewall necessario**: limita l’esposizione delle porte solo a quelle strettamente necessarie.
- **Sincronizzazione dell’orario**: assicurati che l’host usi NTP per evitare problemi legati al tempo (es. certificati TLS).

> **Sicurezza:** i container girano con privilegi elevati (no rootless o user namespace remapping). Massima flessibilità, ma richiede consapevolezza.
>
> **Persistenza dati:** `./projects` per i playbook, `./data` per database e configurazioni. Personalizzabili via variabili d’ambiente. Effettua backup regolari.

---

## Avvio rapido

### Metodo manuale (senza `make`)

```bash
git clone https://github.com/lineadicomando/ansvil.git
cd ansvil
cp .env.example .env  # configura le variabili d’ambiente
docker compose up -d
````

### Metodo con `make` (più semplice)

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

## Hook di inizializzazione (`entrypoint.d/`)

ANSVIL supporta hook modulari eseguibili in tre momenti chiave del ciclo di vita del container:

### Struttura delle directory

```
/entrypoint.d/
├── root/   → script eseguiti come utente root
└── user/   → script eseguiti come utente applicativo (es. ansvil)
```

### Eventi disponibili

| Evento  | Momento                                      | Descrizione                                                 |
| ------- | -------------------------------------------- | ----------------------------------------------------------- |
| `init`  | Solo al primo avvio del container            | Inizializzazione (es. installazioni, configurazioni, setup) |
| `start` | A ogni avvio del container                   | Post-avvio dei servizi (es. trigger, healthcheck)           |
| `exit`  | Alla chiusura del container (SIGTERM/SIGINT) | Pulizia, salvataggio, notifiche finali                      |

### Convenzione di naming

```
NN-<evento>-<descrizione>.sh
```

Esempi:

* `10-init-install-ansible.sh`
* `20-start-healthcheck.sh`
* `99-exit-cleanup.sh`

Gli script vengono eseguiti in ordine crescente, separatamente per `root` e `user`.

### Inizializzazione automatica

Se le directory `/entrypoint.d/root/` o `/entrypoint.d/user/` non esistono, ANSVIL copia automaticamente un template base da `/template/entrypoint.d/`, pronto per essere personalizzato e montato nel volume `/data`.

### Esempio: hook user/init

```bash
#!/bin/bash
echo ">> [user/init] Installazione iniziale delle collection Ansible"

# ansible-galaxy collection install community.general
# pip install netaddr passlib
```

---

## Licenza e componenti open-source

ANSVIL è distribuito sotto [Licenza MIT](LICENSE).
Include o si connette a software open-source con licenze distinte:

* **Ansible** – GNU GPL v3
* **Code-Server** – MIT
* **Semaphore UI** – MIT
* **MariaDB** – GNU GPL v2
* **Nginx** – Licenza tipo BSD

Verifica le licenze ufficiali dei singoli componenti per un uso conforme, specialmente in contesti aziendali o di ridistribuzione.