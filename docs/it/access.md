> 🇬🇧 [English version](../en/access.md)

# Accesso e credenziali

Una volta avviato Ansvil, puoi accedere all'interfaccia web tramite browser:

https://127.0.0.1 oppure https://localhost

Comparirà una **pagina di benvenuto** con collegamenti diretti a:

* **Code-Server**
* **Semaphore UI**

## Accesso da altri dispositivi (LAN)

Se l'host è configurato correttamente (hostname, firewall, DNS locale), puoi accedere anche dalla rete locale:

* tramite **hostname locale** (es. `https://ansvil.local`)
* oppure con **IP privato** (es. `https://192.168.1.42`)

In entrambi i casi, **basta che la porta `443` sia raggiungibile**.
Non è necessario esporre direttamente le porte `8080` o `3000`.

## Credenziali predefinite

| Servizio         | Utente       | Password                   |
| ---------------- | ------------ | -------------------------- |
| **Code-Server**  |              | `ansvil` *(solo password)* |
| **Semaphore UI** | `admin`      | `ansvil`                   |

Puoi modificare tutte le credenziali iniziali tramite il file `.env`.
