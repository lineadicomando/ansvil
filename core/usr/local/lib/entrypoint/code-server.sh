routine_init_code_server() {
  log INFO "Init Code-Server Routine"
  # === Start Code Server configuration ===
  CS_AUTH_TYPE="password"
  CS_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/code-server"
  CS_CONFIG_FILE="${CS_CONFIG_DIR}/config.yaml"

  if [[ ! -f "$CS_CONFIG_FILE" ]]; then
    log INFO "Generating code-server config file"
    HASHED_PASSWORD=$(echo -n "${CODE_SERVER_DEFAULT_PASSWORD}" | argon2 $(openssl rand -base64 16) | grep '^Encoded:' | awk '{print $2}')
    if [[ -z "${HASHED_PASSWORD}" ]]; then
      die "Password hashing failed"
    fi

    mkdir -p "${CS_CONFIG_DIR}"
    {
      echo "bind-addr: 127.0.0.1:8080"
      echo "auth: ${CS_AUTH_TYPE}"
      echo "hashed-password: \"${HASHED_PASSWORD}\""
      echo "disable-telemetry: true"
      echo "cert: false"
    } > "${CS_CONFIG_FILE}"

    chown "${ANSVIL_USER}:${ANSVIL_USER}" "${CS_CONFIG_FILE}"
    chmod 600 "${CS_CONFIG_FILE}"
    log INFO "Code-server config created: ${CS_CONFIG_FILE}"
  fi

  # Set permissions for the Code Server config directory and file
  chown -R "${ANSVIL_USER}:${ANSVIL_USER}" "${CS_CONFIG_DIR}"
  chmod 700 "${CS_CONFIG_DIR}"
  chmod 600 "${CS_CONFIG_FILE}"
}


routine_start_code_server() {
  log INFO "Starting code-server..."

  su "${ANSVIL_USER}" -c "source /venv/bin/activate && code-server ${ANSVIL_DEFAULT_PROJECTS_PATH}" &
  CODE_SERVER_PID=$!

  # Verifica se il processo è partito
  if ! kill -0 "$CODE_SERVER_PID" 2>/dev/null; then
    die "code-server process failed to start (PID=$CODE_SERVER_PID)"
  fi
}
