#!/bin/bash

set -euo pipefail

# === USAGE FUNCTION ===
usage() {
  cat <<EOF
Usage: $(basename "$0") [PASSWORD]

Update the code-server password.
If PASSWORD is omitted, the script will prompt interactively.

Environment variables required:
  ANSVIL_USER_HOME  Path to the user's home directory
  ANSVIL_USER       Username to own the config file
EOF
}

# === PARSE ARGS ===
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
  usage
  exit 0
fi

# === CHECK REQUIRED ENV VARS ===
: "${ANSVIL_USER_HOME:?Environment variable ANSVIL_USER_HOME is required}"
: "${ANSVIL_USER:?Environment variable ANSVIL_USER is required}"

# === CONFIGURATION ===
CS_CONFIG_DIR="${ANSVIL_USER_HOME}/.config/code-server"
CS_CONFIG_FILE="${CS_CONFIG_DIR}/config.yaml"

# === FUNCTIONS ===
source /usr/local/lib/entrypoint/common.sh
# log() { echo "[$1] $2"; }
# die() { echo "[ERROR] $1" >&2; exit 1; }

# === GET PASSWORD ===
if [[ -n "${1:-}" ]]; then
  PASSWORD="$1"
else
  read -s -p "Enter new code-server password: " PASSWORD
  echo
  read -s -p "Confirm new code-server password: " PASSWORD_CONFIRM
  echo

  if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    die "Passwords do not match. Aborting."
  fi
fi

# === CHECK CONFIG FILE ===
if [[ ! -f "$CS_CONFIG_FILE" ]]; then
  die "Configuration file not found: $CS_CONFIG_FILE"
fi

# === STORE ORIGINAL PERMISSIONS ===
ORIG_MODE=$(stat -c "%a" "$CS_CONFIG_FILE")
ORIG_OWNER=$(stat -c "%u:%g" "$CS_CONFIG_FILE")
chmod u+w "$CS_CONFIG_FILE"

# === GENERATE HASHED PASSWORD ===
HASHED_PASSWORD=$(echo -n "$PASSWORD" | argon2 $(openssl rand -base64 16) | grep '^Encoded:' | awk '{print $2}')

if [[ -z "$HASHED_PASSWORD" ]]; then
  die "Password hashing failed"
fi

# === UPDATE CONFIG FILE ===
TMP_FILE="$(mktemp "${CS_CONFIG_DIR}/config.yaml.tmp.XXXX")"
sed -E "s|^hashed-password:.*|hashed-password: \"$HASHED_PASSWORD\"|" "$CS_CONFIG_FILE" > "$TMP_FILE"
cat "$TMP_FILE" > "$CS_CONFIG_FILE"
rm -f "$TMP_FILE"

# === RESTORE ORIGINAL PERMISSIONS ===
chown "$ORIG_OWNER" "$CS_CONFIG_FILE"
chmod "$ORIG_MODE" "$CS_CONFIG_FILE"

log INFO "Password updated successfully in $CS_CONFIG_FILE"
log INFO "Please restart the service to apply changes."
