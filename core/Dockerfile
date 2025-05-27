FROM almalinux:9.6

LABEL maintainer="alessandro.gagliano@gmail.com" \
      version="v0.1.7-beta" \
      description="Ansvil: Ansible Workstation with Semaphore UI and Code-Server on AlmaLinux"

ARG ANSVIL_USER=ansvil
ARG ANSVIL_USER_HOME=/home/ansvil
ENV SEMAPHORE_VER=2.14.10

# Install base packages, micro editor and starship prompt
RUN dnf -y install epel-release && \
    dnf -y update && \
    dnf -y install sudo mariadb python3.12 procps-ng psmisc tar vim nmap btop htop wget \
                   iproute net-tools dhcping rsync tree tmux git jq unzip iftop ncdu netcat \
                   tcpdump ipcalc iotop-c bzip2 whois pwgen bind-utils nano bash-completion \
                   policycoreutils-python-utils sshpass argon2 neovim wol libcap arp-scan && \
    curl -sSL https://getmic.ro | bash && mv micro /usr/bin/ && \
    wget -q -O /tmp/starship.sh https://starship.rs/install.sh && \
    chmod +x /tmp/starship.sh && /tmp/starship.sh -y && \
    rm -f /tmp/starship.sh && \
    # Install code-server and semaphore UI
    curl -fsSL https://code-server.dev/install.sh | sh && \
    curl -L https://github.com/ansible-semaphore/semaphore/releases/download/v${SEMAPHORE_VER}/semaphore_${SEMAPHORE_VER}_linux_amd64.tar.gz | \
    tar -xz && mv semaphore /usr/local/bin/semaphore && \
    dnf clean all

# Shell customization
COPY etc/profile.d/starship.sh /etc/profile.d/
COPY etc/profile.d/aliases.sh /etc/profile.d/
COPY etc/starship.toml /etc/

# Create ansvil user
RUN useradd -m -d ${ANSVIL_USER_HOME} -s /bin/bash -u 1000 -G wheel ${ANSVIL_USER} && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers


USER ${ANSVIL_USER}
WORKDIR ${ANSVIL_USER_HOME}

# Create Python virtual environment and install Ansible tools
RUN python3.12 -m venv ${ANSVIL_USER_HOME}/venv && \
    ${ANSVIL_USER_HOME}/venv/bin/pip install --upgrade pip && \
    ${ANSVIL_USER_HOME}/venv/bin/pip install ansible ansible-lint ansible-creator && \
    mkdir -p ${ANSVIL_USER_HOME}/.bashrc.d

COPY user/bashrc.d/venv.sh ${ANSVIL_USER_HOME}/.bashrc.d/venv.sh

USER root

# Entrypoint configuration
COPY entrypoint.sh /entrypoint.sh
COPY entrypoint.d /template/entrypoint.d

CMD ["/bin/bash", "/entrypoint.sh"]