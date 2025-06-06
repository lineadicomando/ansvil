🇮🇹 [Versione italiana](../it/prerequisiti.md)

# Prerequisites

Ansvil relies on containers to run its services. You need Docker (with the Compose plugin) or Podman (with `podman-compose` and `podman-docker`) and `make` installed on your host.

This guide assumes a minimal installation of AlmaLinux/Fedora or Debian.

## Install Docker on AlmaLinux or Fedora

1. Remove any existing Docker packages:
   ```bash
   sudo dnf remove docker docker-engine docker.io containerd runc
   ```
2. Enable the official Docker repository:
   ```bash
   sudo dnf install -y dnf-plugins-core
   sudo dnf config-manager --add-repo https://download.docker.com/linux/$(. /etc/os-release && echo $ID)/docker-ce.repo
   ```
3. Install Docker Engine and the Compose plugin together with `make`:
   ```bash
   sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin make
   ```
4. Enable and start the service:
   ```bash
   sudo systemctl enable --now docker
   ```

You can install Podman as an alternative:
```bash
sudo dnf install podman podman-compose podman-docker
```

## Install Docker on Debian

1. Remove any existing Docker packages:
   ```bash
   sudo apt-get remove docker docker-engine docker.io containerd runc
   ```
2. Add the official Docker repository:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo $ID)/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo $ID) $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   ```
3. Install Docker Engine, the Compose plugin and `make`:
   ```bash
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin make
   ```
4. Start the service:
   ```bash
   sudo systemctl enable --now docker
   ```

For Podman on Debian:
```bash
sudo apt-get install podman podman-compose podman-docker
```

After installing Docker or Podman, `make up` will start Ansvil.
