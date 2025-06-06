> 🇬🇧 [English version](../en/hooks.md)

# Hook di inizializzazione (`entrypoint.d/`)

Ansvil supporta **hook modulari** eseguibili in fasi chiave del ciclo di vita dei container.

## Struttura delle directory

```
/entrypoint.d/
├── root/   → script eseguiti come utente root
└── user/   → script eseguiti come utente applicativo (es. ansvil)
```

## Eventi disponibili

| Evento  | Momento                                       | Descrizione |
| ------- | --------------------------------------------- | ---------------------------- |
| `init`  | Solo al primo avvio (creazione del container) | Setup iniziale, installazioni, bootstrap |
| `start` | A ogni avvio del container                    | Post-avvio, healthcheck, trigger custom |
| `exit`  | Alla chiusura (SIGTERM/SIGINT)                | Pulizia finale, salvataggi, notifiche |

## Convenzione di naming

```
NN-<evento>-<descrizione>.sh
```

Esempi:

* `10-init-install-ansible.sh`
* `20-start-healthcheck.sh`
* `99-exit-cleanup.sh`

Gli script sono ordinati ed eseguiti in ordine crescente, per `root` e `user` separatamente.

## Inizializzazione automatica

Se le directory `entrypoint.d/root/` o `entrypoint.d/user/` mancano, Ansvil copierà un template base da `/template/entrypoint.d/`.
Personalizzabile e montabile su `/data`.

## Esempio: hook user/init

```bash
#!/bin/bash
echo ">> [user/init] Installazione iniziale delle collection Ansible"

# ansible-galaxy collection install community.general
# pip install netaddr passlib
```
