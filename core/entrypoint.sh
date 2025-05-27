#!/bin/bash
set -euo pipefail

# === Logging utility ===
log() {
  echo "[Entrypoint] >> $*"
}

# === Environment validation ===
: "${ANSVIL_USER:?ANSVIL_USER not set}"
: "${ANSVIL_USER_HOME:?ANSVIL_USER_HOME not set}"
: "${ANSVIL_PROJECTS_PATH:?ANSVIL_PROJECTS_PATH not set}"
: "${SEMAPHORE_DB_HOST:?}"
: "${SEMAPHORE_DB_PORT:?}"
: "${SEMAPHORE_DB_NAME:?}"
: "${SEMAPHORE_DB_USER:?}"
: "${SEMAPHORE_DB_PASS:?}"
: "${SEMAPHORE_ADMIN_USER:?}"
: "${SEMAPHORE_ADMIN_NAME:?}"
: "${SEMAPHORE_ADMIN_EMAIL:?}"
: "${SEMAPHORE_ADMIN_DEFAULT_PASSWORD:?}"
: "${CODE_SERVER_BIND_ADDR:?}"
: "${CODE_SERVER_DEFAULT_PASSWORD:?}"

# === Function: Wait for MariaDB to be ready ===
wait_for_mariadb() {
  local host="${1:-127.0.0.1}"
  local user="${2:-root}"
  local password="${3:-}"
  local port="${4:-3306}"
  local max_retries="${5:-30}"
  local retry_interval="${6:-2}"

  log "Waiting for MariaDB at $host:$port (user: $user)..."

  for ((i=1; i<=max_retries; i++)); do
    if mysqladmin ping -h"$host" -P"$port" -u"$user" -p"$password" --silent > /dev/null 2>&1; then
      log "MariaDB is up and running."
      return 0
    fi
    log "Attempt $i/$max_retries: MariaDB not ready, retrying in $retry_interval seconds..."
    sleep "$retry_interval"
  done

  echo "!! ERROR: Timeout waiting for MariaDB after $((max_retries * retry_interval)) seconds." >&2
  return 1
}

# === Function: Entrypoint Hooks ===
run_entrypoint_hooks() {
  local stage="$1"
  local mode="$2"
  local dir="/entrypoint.d/$mode"

  [ -d "$dir" ] || return

  for f in "$dir"/*-"$stage"-*.sh; do
    [ -f "$f" ] || continue
    log "[$stage/$mode] Executing: $f"

    case "$mode" in
      root)
        . "$f"
        ;;
      user)
        su - "$ANSVIL_USER" -c "bash -c '. \"$f\"'"
        ;;
    esac
  done
}

# === Set entrypoint.d ===
for role in root user; do
  if [ ! -d "/entrypoint.d/${role}" ] && [ -d "/template/entrypoint.d/${role}" ]; then
    log "First boot: copying hooks for ${role}"
    mkdir -p "/entrypoint.d/${role}"
    cp -rf "/template/entrypoint.d/${role}" /entrypoint.d/
    chown -R "${ANSVIL_USER}:${ANSVIL_USER}" /entrypoint.d
    find /entrypoint.d/ -type f -exec chmod +x {} \;
  fi
done

run_entrypoint_hooks init root
run_entrypoint_hooks init user

# === Ensure project directory exists ===
if [[ ! -d "${ANSVIL_PROJECTS_PATH}" ]]; then
  log "Creating project directory: ${ANSVIL_PROJECTS_PATH}"
  mkdir -p "${ANSVIL_PROJECTS_PATH}"
fi

# === Start Code Server configuration ===
CS_AUTH_TYPE="password"
CS_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/code-server"
CS_CONFIG_FILE="${CS_CONFIG_DIR}/config.yaml"

if [[ ! -f "$CS_CONFIG_FILE" ]]; then
  log "Generating code-server config file"
  HASHED_PASSWORD=$(echo -n "${CODE_SERVER_DEFAULT_PASSWORD}" | argon2 --encode | grep '^Encoded:' | awk '{print $2}')
  if [[ -z "${HASHED_PASSWORD}" ]]; then
    echo "ERROR: Password hashing failed"
    exit 1
  fi

  mkdir -p "${CS_CONFIG_DIR}"
  cat > "${CS_CONFIG_FILE}" <<EOF
bind-addr: ${CODE_SERVER_BIND_ADDR}
auth: ${CS_AUTH_TYPE}
hashed-password: "${HASHED_PASSWORD}"
disable-telemetry: true
cert: false
EOF

  chown "${ANSVIL_USER}:${ANSVIL_USER}" "${CS_CONFIG_FILE}"
  chmod 600 "${CS_CONFIG_FILE}"
  log "Code-server config created: ${CS_CONFIG_FILE}"
fi

# === Start Semaphore configuration ===
SM_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/semaphore"
SM_CONFIG_FILE="${SM_CONFIG_DIR}/config.json"

if [ ! -f "${SM_CONFIG_FILE}" ]; then
  log "Semaphore config file not found, creating it ${SM_CONFIG_FILE}"

  mkdir -p "${SM_CONFIG_DIR}"
  cat << EOF > "${SM_CONFIG_FILE}"
{
  "mysql": {
    "host": "${SEMAPHORE_DB_HOST}:${SEMAPHORE_DB_PORT}",
    "name": "${SEMAPHORE_DB_NAME}",
    "user": "${SEMAPHORE_DB_USER}",
    "pass": "${SEMAPHORE_DB_PASS}"
  },
  "dialect": "mysql",
  "tmp_path": "${ANSVIL_PROJECTS_PATH}",
  "web_host": "/semaphore",
  "cookie_hash": "4DOz2jNdJAg23M5u91iOolcf3jEpcoFWoOWm9zVKOUg=",
  "cookie_encryption": "vnS+otiskwlSQ6BnAYW1UjrUfpDomf9xQ0zSUn2BU6c=",
  "access_key_encryption": "4BHnW72wa5+h7t5pzehkCtDny6Aa8IqMQ3mC9VAipcg="
}
EOF

  wait_for_mariadb "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_USER" "$SEMAPHORE_DB_PASS" "$SEMAPHORE_DB_PORT" 30 2 || exit 1
else
  log "Semaphore config file already exists: ${SM_CONFIG_FILE}"
fi

log "Running Semaphore database migrations"
wait_for_mariadb "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_USER" "$SEMAPHORE_DB_PASS" "$SEMAPHORE_DB_PORT" 30 2 || exit 1
semaphore migrate --config "${SM_CONFIG_FILE}"

log "Checking if Semaphore admin user '${SEMAPHORE_ADMIN_USER}' exists..."
if ! semaphore user list --config "${SM_CONFIG_FILE}" | grep -q "^${SEMAPHORE_ADMIN_USER}$"; then
  log "Creating Semaphore admin user '${SEMAPHORE_ADMIN_USER}'"
  semaphore user add --admin \
    --login "${SEMAPHORE_ADMIN_USER}" \
    --password "${SEMAPHORE_ADMIN_DEFAULT_PASSWORD}" \
    --name "${SEMAPHORE_ADMIN_NAME}" \
    --email "${SEMAPHORE_ADMIN_EMAIL}" \
    --config "${SM_CONFIG_FILE}"
else
  log "Admin user '${SEMAPHORE_ADMIN_USER}' already exists, skipping creation"
fi

# === Signal handling ===
_term() {
  log "Caught SIGTERM, stopping services..."
  kill -TERM "${CODE_SERVER_PID}" "${SEMAPHORE_PID}" 2>/dev/null
  wait "${CODE_SERVER_PID}" "${SEMAPHORE_PID}"
  log "All services stopped"

  run_entrypoint_hooks exit root
  run_entrypoint_hooks exit user
  exit 0
}
trap _term SIGTERM SIGINT

# === Start services ===
log "Starting code-server..."
su "${ANSVIL_USER}" -c "source ${ANSVIL_USER_HOME}/bin/activate && code-server ${ANSVIL_PROJECTS_PATH}" &
CODE_SERVER_PID=$!

log "Starting semaphore..."
wait_for_mariadb "$SEMAPHORE_DB_HOST" "$SEMAPHORE_DB_USER" "$SEMAPHORE_DB_PASS" "$SEMAPHORE_DB_PORT" 30 2 || exit 1
su "${ANSVIL_USER}" -c "source ${ANSVIL_USER_HOME}/bin/activate && semaphore server --config ${SM_CONFIG_FILE}" &
SEMAPHORE_PID=$!

run_entrypoint_hooks start root
run_entrypoint_hooks start user

wait "$CODE_SERVER_PID" "$SEMAPHORE_PID"
