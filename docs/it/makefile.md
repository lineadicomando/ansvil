> 🇬🇧 [English version](../en/makefile.md)

# Comandi del Makefile

Il Makefile offre scorciatoie per gestire il container. Esegui `make help` per vedere i target disponibili.

| Comando | Descrizione |
| ------- | ----------- |
| `check-env` | Verifica l'esistenza del file `.env` e la disponibilità di root o sudo |
| `ps` | Mostra lo stato dei servizi Docker Compose |
| `status` | Alias di `ps` |
| `up` | Avvia i servizi Docker Compose in background |
| `down` | Ferma e rimuove i servizi Docker Compose |
| `start` | Avvia i container esistenti |
| `stop` | Ferma i container senza rimuoverli |
| `restart` | Riavvia i servizi Docker Compose (ricostruzione completa) |
| `restart-soft` | Riavvia i servizi senza ricreare i container |
| `logs` | Mostra i log di tutti i servizi |
| `logs-<servizio>` | Mostra i log di un servizio specifico |
| `pull` | Scarica le ultime immagini Docker |
| `update` | Scarica e riavvia tutti i servizi |
| `init` | Inizializza `.env` da `.env.example` |
| `shell` | Entra nella shell del container come utente applicativo |
| `chcodpw` | Cambia la password di Code-Server |
| `chdempw` | Cambia la password di Semaphore UI |
| `root-shell` | Entra nella shell root del container `core` |
| `help` | Mostra i comandi disponibili |

Ulteriori target possono essere definiti in un `Makefile.local` e compariranno alla fine di `make help`.
