#!/bin/bash
set -euo pipefail

for role in root user; do
  if [ ! -d "/entrypoint.d/${role}" ] && [ -d "/template/entrypoint.d/${role}" ]; then
    echo ">> Primo avvio: copia degli hook per ${role}"
    mkdir -p "/entrypoint.d/${role}"
    cp -rf "/template/entrypoint.d/${role}" /entrypoint.d/
    chown -R "${ANSVIL_USER}:${ANSVIL_USER}" /entrypoint.d
    find /entrypoint.d/ -type f -exec chmod +x {} \;
  fi
done

if [ ! -f "${ANSVIL_USER_HOME}/.bashrc.d/venv.sh" ] && [ -f "/template/user/bashrc.d/venv.sh" ]; then
  cp -f "/template/user/bashrc.d/venv.sh" "${ANSVIL_USER_HOME}/.bashrc.d/venv.sh"
  chmod +x "${ANSVIL_USER_HOME}/.bashrc.d/venv.sh"
  chown "${ANSVIL_USER}:${ANSVIL_USER}" "${ANSVIL_USER_HOME}/.bashrc.d/venv.sh"
fi

# === Function: Wait for MariaDB to be ready ===
wait_for_mariadb() {
  local host="${1:-127.0.0.1}"
  local user="${2:-root}"
  local password="${3:-}"
  local port="${4:-3306}"
  local max_retries="${5:-30}"
  local retry_interval="${6:-2}"

  echo ">> Waiting for MariaDB at $host:$port (user: $user)..."

  for ((i=1; i<=max_retries; i++)); do
    if mysqladmin ping -h"$host" -P"$port" -u"$user" -p"$password" --silent > /dev/null 2>&1; then
      echo ">> MariaDB is up and running."
      return 0
    fi
    echo ">> Attempt $i/$max_retries: MariaDB not ready, retrying in $retry_interval seconds..."
    sleep "$retry_interval"
  done

  echo "!! ERROR: Timeout waiting for MariaDB after $((max_retries * retry_interval)) seconds." >&2
  return 1
}

run_entrypoint_hooks() {
  local stage="$1"   # init | start | exit
  local mode="$2"    # root | user
  local dir="/entrypoint.d/$mode"

  [ -d "$dir" ] || return

  for f in "$dir"/*-"$stage"-*.sh; do
    [ -f "$f" ] || continue
    echo ">> [$stage/$mode] Executing: $f"

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

run_entrypoint_hooks init root "/.firstboot-init-root.done"
run_entrypoint_hooks init user "/.firstboot-init-user.done"

# === Ensure project directory exists ===
if [[ ! -d "${ANSVIL_PROJECTS_PATH}" ]]; then
  echo ">> Creating project directory: ${ANSVIL_PROJECTS_PATH}"
  mkdir -p "${ANSVIL_PROJECTS_PATH}"
fi

# === Code Server configuration ===
CS_AUTH_TYPE="password"
CS_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/code-server"
CS_CONFIG_FILE="${CS_CONFIG_DIR}/config.yaml"

if [[ ! -f "$CS_CONFIG_FILE" ]]; then
  echo ">> Generating code-server config file"
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
EOF

  chown "${ANSVIL_USER}:${ANSVIL_USER}" "${CS_CONFIG_FILE}"
  chmod 600 "${CS_CONFIG_FILE}"
  echo ">> Code-server config created: ${CS_CONFIG_FILE}"
fi

# === Semaphore configuration ===
SM_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/semaphore"
SM_CONFIG_FILE="${SM_CONFIG_DIR}/config.json"

if [[ ! -f "${SM_CONFIG_FILE}" ]]; then
  echo ">> Creating Semaphore config file"

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

  # Wait for MariaDB to be available
  wait_for_mariadb "${SEMAPHORE_DB_HOST}" "${SEMAPHORE_DB_USER}" "${SEMAPHORE_DB_PASS}" "${SEMAPHORE_DB_PORT}" 30 2 || exit 1

  echo ">> Running Semaphore database migrations"
  semaphore migrate --config "${SM_CONFIG_FILE}"

  echo ">> Creating Semaphore admin user"
  semaphore user add --admin \
    --login "${SEMAPHORE_ADMIN_USER}" \
    --password "${SEMAPHORE_ADMIN_DEFAULT_PASSWORD}" \
    --name "${SEMAPHORE_ADMIN_NAME}" \
    --email "${SEMAPHORE_ADMIN_EMAIL}" \
    --config "${SM_CONFIG_FILE}"
fi

# === Fix ownership ===
chown -R "${ANSVIL_USER}:${ANSVIL_USER}" "${ANSVIL_USER_HOME}"
chown -R "${ANSVIL_USER}:${ANSVIL_USER}" "${ANSVIL_PROJECTS_PATH}"

# === Signal handling ===
_term() {

  echo ">> Caught SIGTERM, stopping services..."
  kill -TERM "${CODE_SERVER_PID}" "${SEMAPHORE_PID}" 2>/dev/null
  wait "${CODE_SERVER_PID}" "${SEMAPHORE_PID}"
  echo ">> All services stopped"

  run_entrypoint_hooks exit root
  run_entrypoint_hooks exit user

  exit 0

}

trap _term SIGTERM SIGINT

# === Start services ===

echo ">> Starting code-server..."
su "${ANSVIL_USER}" -c "source ${ANSVIL_USER_HOME}/bin/activate && code-server" &
# su "${ANSVIL_USER}" -c "code-server" &
CODE_SERVER_PID=$!

echo ">> Starting semaphore..."
su "${ANSVIL_USER}" -c "source ${ANSVIL_USER_HOME}/bin/activate && semaphore server --config ${SM_CONFIG_FILE}" &
# su "${ANSVIL_USER}" -c "semaphore server --config ${SM_CONFIG_FILE}" &
SEMAPHORE_PID=$!

run_entrypoint_hooks start root
run_entrypoint_hooks start user

# === Wait for both processes ===
wait "$CODE_SERVER_PID" "$SEMAPHORE_PID"
