#!/usr/bin/env bash

routine_init_user() {
  # Create user if not exists
  if id "${ANSVIL_USER}" &>/dev/null; then
      log INFO "User ${ANSVIL_USER} already exists."
  else
      useradd -m -d "${ANSVIL_USER_HOME}" -s /bin/bash -u ${ANSVIL_USER_ID:-1000} -G wheel "${ANSVIL_USER}"
      log INFO "User ${ANSVIL_USER} created."
  fi

  # Grant passwordless sudo to wheel group
  if ! grep -q '^%wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers; then
      echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
  fi
}
