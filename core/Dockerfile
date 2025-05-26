FROM almalinux:9.6

LABEL maintainer="alessandro.gagliano@gmail.com"
LABEL version="v0.1.3-beta"
LABEL description="Ansvil: Ansible Workstation con Semaphore UI e Code-Server su AlmaLinux"

ARG ANSVIL_USER=ansvil
ARG ANSVIL_USER_HOME=/home/ansvil

ENV SEMAPHORE_VER=2.14.10
ENV DEBIAN_FRONTEND=noninteractive

# Aggiornamento e pacchetti base
RUN dnf -y install epel-release \
    && dnf -y update \
    && dnf -y install sudo mariadb python3.12 procps-ng psmisc tar vim nmap btop htop wget net-tools dhcping rsync tree tmux git jq unzip iftop ncdu netcat tcpdump ipcalc iotop-c bzip2 whois pwgen bind-utils nano bash-completion policycoreutils-python-utils sshpass argon2 neovim wol libcap arp-scan \
    && dnf clean all \
    && curl https://getmic.ro | bash \
    && mv micro /usr/bin/ \
    ;

# Shell
RUN wget -P /tmp https://starship.rs/install.sh \
    && chmod +x /tmp/install.sh && /tmp/install.sh -y && rm -f /tmp/install.sh  \
    ;
COPY etc/profile.d/starship.sh /etc/profile.d/starship.sh
COPY etc/profile.d/aliases.sh /etc/profile.d/aliases.sh
COPY etc/starship.toml /etc/starship.toml

# User
RUN useradd -m -d ${ANSVIL_USER_HOME} -s /bin/bash -u 1000 -G wheel ${ANSVIL_USER} \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && mkdir -p /home/${ANSVIL_USER}/.bashrc.d \
    && chown -R ${ANSVIL_USER}:${ANSVIL_USER} /home/${ANSVIL_USER} \
    ;


USER ${ANSVIL_USER}
WORKDIR ${ANSVIL_USER_HOME}

RUN python3.12 -m venv ${ANSVIL_USER_HOME}/ \
    && source ${ANSVIL_USER_HOME}/bin/activate \
    && pip install --upgrade pip \
    && pip install ansible ansible-lint ansible-creator \
    ;

COPY user/bashrc.d/venv.sh ${ANSVIL_USER_HOME}/.bashrc.d/venv.sh

USER root

RUN curl -fsSL https://code-server.dev/install.sh | sh


RUN curl -L https://github.com/ansible-semaphore/semaphore/releases/download/v${SEMAPHORE_VER}/semaphore_${SEMAPHORE_VER}_linux_amd64.tar.gz \
    | tar -xz && \
    mv semaphore /usr/local/bin/semaphore

COPY entrypoint.sh /entrypoint.sh
COPY user /template/user
COPY entrypoint.d /template/entrypoint.d

CMD ["/bin/bash", "/entrypoint.sh"]
