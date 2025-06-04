FROM almalinux:9.6

LABEL maintainer="alessandro.gagliano@gmail.com" \
      version="v0.1.10-beta" \
      description="Ansvil: Ansible Workstation with Semaphore UI and Code-Server on AlmaLinux"

ARG ANSVIL_USER=ansvil
ARG ANSVIL_USER_HOME=/ansvil
ENV SEMAPHORE_VER=2.14.10

COPY etc/profile.d/starship.sh /etc/profile.d/
COPY etc/profile.d/aliases.sh /etc/profile.d/
COPY etc/starship.toml /etc/

RUN <<EOC
dnf -y install epel-release
    dnf -y update
    dnf -y install sudo mariadb python3.12 procps-ng psmisc tar vim nmap btop htop wget \
                   iproute net-tools dhcping rsync tree tmux git jq unzip iftop ncdu netcat \
                   tcpdump ipcalc iotop-c bzip2 whois pwgen bind-utils nano bash-completion \
                   policycoreutils-python-utils sshpass argon2 neovim wol libcap arp-scan \
                   make
    curl -sSL https://getmic.ro | bash && mv micro /usr/bin/
    wget -q -O /tmp/starship.sh https://starship.rs/install.sh
    chmod +x /tmp/starship.sh && /tmp/starship.sh -y
    rm -f /tmp/starship.sh
    # Install code-server and semaphore UI
    curl -fsSL https://code-server.dev/install.sh | sh
    curl -L https://github.com/ansible-semaphore/semaphore/releases/download/v${SEMAPHORE_VER}/semaphore_${SEMAPHORE_VER}_linux_amd64.tar.gz | \
    tar -xz && mv semaphore /usr/local/bin/semaphore
    dnf clean all
    # Create ansvil user
    useradd -m -d ${ANSVIL_USER_HOME} -s /bin/bash -u 1000 -G wheel ${ANSVIL_USER}
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
    mkdir /venv
    chown -R ${ANSVIL_USER}:${ANSVIL_USER} /venv
EOC

USER ${ANSVIL_USER}
WORKDIR ${ANSVIL_USER_HOME}

RUN <<EOC
python3.12 -m venv /venv
/venv/bin/pip install --upgrade pip
/venv/bin/pip install ansible ansible-lint ansible-creator

# Append VEnv activation directly into .bashrc
cat <<EOF >> ${ANSVIL_USER_HOME}/.bashrc

# >>> VEnv activation >>>
if [ -f /venv/bin/activate ]; then
    source /venv/bin/activate
fi
# <<< VEnv activation <<<
EOF

EOC

USER root

COPY usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY usr/local/lib/entrypoint /usr/local/lib/entrypoint
COPY usr/local/share/templates/entrypoint.d /usr/local/share/templates/entrypoint.d

CMD ["/bin/bash", "/usr/local/bin/entrypoint.sh"]