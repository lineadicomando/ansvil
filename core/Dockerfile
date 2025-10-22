FROM almalinux:10

LABEL maintainer="alessandro.gagliano@gmail.com" \
      version="v0.2.01-beta" \
      description="Ansvil: Ansible Workstation with Semaphore UI and Code-Server on AlmaLinux"

ARG ANSVIL_USER=ansvil
ARG ANSVIL_USER_HOME=/ansvil
ENV SEMAPHORE_VER=2.16.32

RUN <<EOF

# Install dependencies and tools
dnf -y install epel-release
dnf -y update
dnf -y install sudo mariadb-client-utils python3.12 procps-ng psmisc tar vim nmap btop htop wget \
                iproute net-tools rsync tree tmux git jq unzip iftop ncdu netcat \
                tcpdump ipcalc iotop-c bzip2 whois openssl bind-utils nano bash-completion \
                policycoreutils-python-utils sshpass argon2 neovim net-tools iputils nmap libcap \
                make nodejs

dnf clean all
rm -rf /var/cache/dnf /tmp/* /var/tmp/*

# Install micro
curl -sSL https://getmic.ro | bash && mv micro /usr/bin/

# Install starship
wget -q -O /tmp/starship.sh https://starship.rs/install.sh
chmod +x /tmp/starship.sh && /tmp/starship.sh -y
rm -f /tmp/starship.sh /root/.cache /root/.cargo

# Install code-server
curl -fsSL https://code-server.dev/install.sh | sh
rm -rf /root/.cache

# Install semaphore UI
curl -L https://github.com/ansible-semaphore/semaphore/releases/download/v${SEMAPHORE_VER}/semaphore_${SEMAPHORE_VER}_linux_amd64.tar.gz | \
tar -xz && mv semaphore /usr/local/bin/semaphore
rm -f semaphore_*.tar.gz

# Create ansvil user
useradd -m -d ${ANSVIL_USER_HOME} -s /bin/bash -u 1000 -G wheel ${ANSVIL_USER}
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

EOF

COPY etc/profile.d /etc/profile.d
COPY etc/starship.toml /etc/
COPY usr/local/bin /usr/local/bin
COPY usr/local/lib/entrypoint /usr/local/lib/entrypoint
COPY usr/local/share/templates/entrypoint.d /usr/local/share/templates/entrypoint.d

CMD ["/bin/bash", "/usr/local/bin/entrypoint.sh"]