routine_init_code_server() {
  log INFO "Init Code-Server Routine"
  # === Start Code Server configuration ===
  CS_AUTH_TYPE="password"
  CS_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/code-server"
  CS_CONFIG_FILE="${CS_CONFIG_DIR}/config.yaml"
  CS_CUSTOM_STRINGS_FILE="${CS_CONFIG_DIR}/custom-strings.json"

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

  if [[ ! -f "$CS_CUSTOM_STRINGS_FILE" ]]; then
    log INFO "Generating code-server custom strings file"

    mkdir -p "${CS_CONFIG_DIR}"
    {
      echo '{'
      echo '"WELCOME": "Welcome to {{app}}",'
      echo '"LOGIN_TITLE": "{{app}} Access Portal",'
      echo '"LOGIN_BELOW": "Please log in to continue",'
      # echo '"LOGIN_PASSWORD": "",'
      echo '"PASSWORD_PLACEHOLDER": "Enter Password"'
      echo "}"
    } > "${CS_CUSTOM_STRINGS_FILE}"

    chown "${ANSVIL_USER}:${ANSVIL_USER}" "${CS_CUSTOM_STRINGS_FILE}"
    chmod 600 "${CS_CUSTOM_STRINGS_FILE}"
    log INFO "Code-server config created: ${CS_CUSTOM_STRINGS_FILE}"
  fi

  # Set permissions for the Code Server config directory and file
  chown -R "${ANSVIL_USER}:${ANSVIL_USER}" "${CS_CONFIG_DIR}"
  chmod 700 "${CS_CONFIG_DIR}"
  chmod 600 "${CS_CONFIG_FILE}"
}


routine_start_code_server() {
  log INFO "Starting code-server..."

  su "${ANSVIL_USER}" -c "source /venv/bin/activate && code-server --app-name '${ANSVIL_CODE_APP_NAME:-Ansvil::Code}' --i18n ${CS_CUSTOM_STRINGS_FILE} ${ANSVIL_DEFAULT_PROJECTS_PATH}" &
  CODE_SERVER_PID=$!

  # Verifica se il processo è partito
  if ! kill -0 "$CODE_SERVER_PID" 2>/dev/null; then
    die "code-server process failed to start (PID=$CODE_SERVER_PID)"
  fi
}
