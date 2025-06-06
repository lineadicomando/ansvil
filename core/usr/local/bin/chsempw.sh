#!/bin/bash

set -euo pipefail


# === CHECK REQUIRED ENV VARS ===
: "${ANSVIL_USER_HOME:?Environment variable ANSVIL_USER_HOME is required}"
: "${SEMAPHORE_ADMIN_USER:?Environment variable SEMAPHORE_ADMIN_USER is required}"

SEMAPHORE_CONFIG="${ANSVIL_USER_HOME}/.config/semaphore/config.json"

# === FUNCTIONS ===
usage() {
  cat <<EOF
Usage: $(basename "$0") [-u USERNAME] [-p PASSWORD]

Change password for a Semaphore UI user.

Options:
  -u, --username     Username to update
  -p, --password     New password (prompted if not provided)
  -l, --list         List existing users
  -h, --help         Show this help message
EOF
}

source /usr/local/lib/entrypoint/common.sh

# die() { echo "[ERROR] $1" >&2; exit 1; }
# log() { echo "[$1] $2"; }

# === PARSE ARGS ===
USERNAME=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--username)
      USERNAME="$2"
      shift 2
      ;;
    -p|--password)
      PASSWORD="$2"
      shift 2
      ;;
    -l|--list)
      semaphore user list --config "$SEMAPHORE_CONFIG"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Unknown option: $1"
      ;;
  esac
done

# === GET MISSING VALUES ===
if [[ -z "$USERNAME" ]]; then
  DEFAULT_USER="${SEMAPHORE_ADMIN_USER:-}"
  read -p "Enter username [${DEFAULT_USER}]: " USERNAME
  USERNAME="${USERNAME:-$DEFAULT_USER}"
  # read -p "Enter username: " USERNAME
fi

# === VERIFY USER EXISTS ===
USER_LIST=$(semaphore user list --config "$SEMAPHORE_CONFIG" | tail -n +3 | awk '{print $1}')
if ! echo "$USER_LIST" | grep -q "^$USERNAME$"; then
  die "User '$USERNAME' not found."
fi

if [[ -z "$PASSWORD" ]]; then
  read -s -p "Enter new password: " PASSWORD
  echo
  read -s -p "Confirm new password: " PASSWORD_CONFIRM
  echo
  if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    die "Passwords do not match. Aborting."
  fi
fi

# === UPDATE PASSWORD ===
semaphore user change-by-login \
  --login "$USERNAME" \
  --password "$PASSWORD" \
  --config "$SEMAPHORE_CONFIG"

log INFO "Password updated for user '$USERNAME'"
