🇬🇧 [English version](../en/prerequisites.md)

# Prerequisiti

Ansvil utilizza container per eseguire i suoi servizi. È necessario installare Docker (con il plugin Compose) oppure Podman (con `podman-compose` e `podman-docker`) e `make` sull'host.

Questa guida è pensata per una installazione minimale di AlmaLinux/Fedora o Debian.

## Installare Docker su AlmaLinux o Fedora

1. Rimuovere eventuali pacchetti Docker già presenti:

   ```bash
   sudo dnf remove docker docker-engine docker.io containerd runc
   ```

2. Abilitare il repository ufficiale di Docker:
   
   Su Fedora
   
   ```bash
   sudo dnf install -y dnf-plugins-core
   sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
   ```
   
   Su AlmaLinux/Rocky Linux

   ```bash
   sudo dnf install -y dnf-plugins-core
   sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
   ```

3. Installare Docker Engine e il plugin Compose insieme a `make`:

   ```bash
   sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin make git
   ```

4. Abilitare e avviare il servizio:

   ```bash
   sudo systemctl enable --now docker
   ```

In alternativa si può installare Podman:

```bash
sudo dnf install podman podman-compose podman-docker
```

## Installare Docker su Debian

1. Rimuovere eventuali versioni precedenti:
   ```bash
   sudo apt-get remove docker docker-engine docker.io containerd runc
   ```
2. Aggiungere il repository ufficiale:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo $ID)/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo $ID) $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   ```
3. Installare Docker Engine, il plugin Compose e `make`:
   ```bash
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin make git
   ```
4. Avviare il servizio:
   ```bash
   sudo systemctl enable --now docker
   ```

Per installare Podman su Debian:
```bash
sudo apt-get install podman podman-compose podman-docker
```

Dopo l'installazione di Docker o Podman, `make up` avvierà Ansvil.
