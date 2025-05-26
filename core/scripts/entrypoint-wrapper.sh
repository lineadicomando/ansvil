#!/bin/bash
set -euo pipefail

# === Function for fix ownership ===

fix_ownership_if_needed() {
  local path="$1"
  local target_usergroup="$2"
  echo "[Entrypoint] >> Check ownership for: $path"

  # Estrai user e group separati
  local target_user="${target_usergroup%%:*}"
  local target_group="${target_usergroup##*:}"

  if [ ! -d "$path" ]; then
    echo "[Entrypoint] >> Skipping: directory not found: $path"
    return
  fi

  local owner=$(stat -c '%U' "$path")
  local group=$(stat -c '%G' "$path")

  if [ "$owner" != "$target_user" ] || [ "$group" != "$target_group" ]; then
    echo "[Entrypoint] >> Fixing ownership of: $path"
    chown -R "${target_user}:${target_group}" "$path"
  else
    echo "[Entrypoint] >> Ownership OK: $path ($owner:$group)"
  fi
}

fix_ownership_if_needed "${ANSVIL_PROJECTS_PATH}" "${ANSVIL_USER}:${ANSVIL_USER}"
fix_ownership_if_needed "${ANSVIL_USER_HOME}/.ansible" "${ANSVIL_USER}:${ANSVIL_USER}"
fix_ownership_if_needed "${ANSVIL_USER_HOME}/.local" "${ANSVIL_USER}:${ANSVIL_USER}"
fix_ownership_if_needed "${ANSVIL_USER_HOME}/.config" "${ANSVIL_USER}:${ANSVIL_USER}"
fix_ownership_if_needed "${ANSVIL_USER_HOME}/.bashrc.d" "${ANSVIL_USER}:${ANSVIL_USER}"


echo "[Entrypoint] Eseguo entrypoint.sh originale"
/entrypoint.sh "$@"