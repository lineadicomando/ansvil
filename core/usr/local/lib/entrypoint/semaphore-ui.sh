# === Function: Wait for MariaDB to be ready ===
wait_for_mariadb() {
  local host="${1:-127.0.0.1}"
  local user="${2:-root}"
  local password="${3:-}"
  local port="${4:-3306}"
  local max_retries="${5:-30}"
  local retry_interval="${6:-2}"
  local quiet="${7:-false}"
  local connect_timeout="${8:-2}"

  # Verifica dipendenza
  if ! command -v mysqladmin >/dev/null 2>&1; then
    log ERROR "mysqladmin non trovato nel PATH."
    return 2
  fi

  # Normalizza numerici
  [[ "$max_retries" =~ ^[0-9]+$ ]] || max_retries=30
  [[ "$retry_interval" =~ ^[0-9]+$ ]] || retry_interval=2
  [[ "$connect_timeout" =~ ^[0-9]+$ ]] || connect_timeout=2

  [[ "$quiet" != "true" ]] && log INFO "Attendo MariaDB su $host:$port (user: $user)..."

  # Costruisci gli argomenti in modo sicuro
  local args=(ping --silent -h"$host" -P"$port" -u"$user" --connect-timeout="$connect_timeout")
  if [[ -n "$password" ]]; then
    args+=("--password=$password")   # evita -p senza argomento
  fi

  local i
  for (( i=1; i<=max_retries; i++ )); do
    if mysqladmin "${args[@]}" >/dev/null 2>&1; then
      [[ "$quiet" != "true" ]] && log INFO "MariaDB è operativo."
      return 0
    fi

    [[ "$quiet" != "true" ]] && log INFO "Tentativo $i/$max_retries: MariaDB non ancora pronto; nuovo tentativo tra ${retry_interval}s..."
    sleep "$retry_interval"
  done

  log ERROR "Timeout dopo $(( max_retries * retry_interval )) secondi in attesa di MariaDB."
  return 1
}


routine_init_semaphore_ui() {
  log INFO "Init Semaphore UI Routine"
  set_status initializing true phase semaphore-ui msg "Initializing Semaphore UI"
  # === Start Semaphore configuration ===
  SM_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/semaphore"
  SM_CONFIG_FILE="${SM_CONFIG_DIR}/config.json"

  if [ ! -f "${SM_CONFIG_FILE}" ]; then
    log INFO "Semaphore config file not found, creating it ${SM_CONFIG_FILE}"

    mkdir -p "${SM_CONFIG_DIR}"
    {
      echo "{"
      echo '  "mysql": {'
      echo "    \"host\": \"${SEMAPHORE_DB_HOST}:${SEMAPHORE_DB_PORT}\","
      echo "    \"name\": \"${SEMAPHORE_DB_NAME}\","
      echo "    \"user\": \"${SEMAPHORE_DB_USER}\","
      echo "    \"pass\": \"${SEMAPHORE_DB_PASS}\""
      echo "  },"
      echo '  "dialect": "mysql",'
      echo "  \"tmp_path\": \"${ANSVIL_DEFAULT_PROJECTS_PATH}\","
      echo '  "web_host": "/semaphore",'
      echo '  "cookie_hash": "4DOz2jNdJAg23M5u91iOolcf3jEpcoFWoOWm9zVKOUg=",'
      echo '  "cookie_encryption": "vnS+otiskwlSQ6BnAYW1UjrUfpDomf9xQ0zSUn2BU6c=",'
      echo '  "access_key_encryption": "4BHnW72wa5+h7t5pzehkCtDny6Aa8IqMQ3mC9VAipcg="'
      echo "}"
    } > "${SM_CONFIG_FILE}"

    wait_for_mariadb "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_USER" "$SEMAPHORE_DB_PASS" "$SEMAPHORE_DB_PORT" 30 2 || die
  else
    log INFO "Semaphore config file already exists: ${SM_CONFIG_FILE}"
  fi

  log INFO "Running Semaphore database migrations"
  wait_for_mariadb "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_USER" "$SEMAPHORE_DB_PASS" "$SEMAPHORE_DB_PORT" 30 2 || die
  semaphore migrate --config "${SM_CONFIG_FILE}"

  log INFO "Checking if Semaphore admin user '${SEMAPHORE_ADMIN_USER}' exists..."
  if ! semaphore user list --config "${SM_CONFIG_FILE}" | grep -q "^${SEMAPHORE_ADMIN_USER}$"; then
    log INFO "Creating Semaphore admin user '${SEMAPHORE_ADMIN_USER}'"
    semaphore user add --admin \
      --login "${SEMAPHORE_ADMIN_USER}" \
      --password "${SEMAPHORE_ADMIN_DEFAULT_PASSWORD}" \
      --name "${SEMAPHORE_ADMIN_NAME}" \
      --email "${SEMAPHORE_ADMIN_EMAIL}" \
      --config "${SM_CONFIG_FILE}"
  else
    log INFO "Admin user '${SEMAPHORE_ADMIN_USER}' already exists, skipping creation"
  fi

  # Set permissions for the Semaphore config directory and file
  log INFO "Setting permissions for Semaphore config directory and file"
  chown -R "${ANSVIL_USER}:${ANSVIL_USER}" "${SM_CONFIG_DIR}"
  chmod 700 "${SM_CONFIG_DIR}"
  chmod 600 "${SM_CONFIG_FILE}"
}


routine_start_semaphore_ui() {
  log INFO "Starting semaphore..."
  

  wait_for_mariadb "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_USER" "$SEMAPHORE_DB_PASS" "$SEMAPHORE_DB_PORT" 30 2 true || die

  su "${ANSVIL_USER}" -c "source /venv/bin/activate && semaphore server --config ${SM_CONFIG_FILE}" &
  SEMAPHORE_PID=$!

  # Verifica se il processo è partito
  if ! kill -0 "$SEMAPHORE_PID" 2>/dev/null; then
    die "Semaphore process failed to start (PID=$SEMAPHORE_PID)"
  fi
}
