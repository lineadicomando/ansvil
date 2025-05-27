#!/bin/bash
set -euo pipefail

# === Validate required env vars ===
: "${ANSVIL_USER:?Environment variable ANSVIL_USER not set}"
: "${ANSVIL_USER_HOME:?Environment variable ANSVIL_USER_HOME not set}"
: "${ANSVIL_PROJECTS_PATH:?Environment variable ANSVIL_PROJECTS_PATH not set}"

log() {
  echo "[Entrypoint-Wrapper] >> $*"
}

fix_ownership_if_needed() {
  local path="$1"
  local target_usergroup="$2"

  log "Checking ownership for: $path"

  if [ ! -e "$path" ]; then
    log "Skipping (not found): $path"
    return
  fi

  local owner group
  owner=$(stat -c '%U' "$path")
  group=$(stat -c '%G' "$path")
  local target_user="${target_usergroup%%:*}"
  local target_group="${target_usergroup##*:}"

  if [[ "$owner" != "$target_user" || "$group" != "$target_group" ]]; then
    log "Fixing ownership of: $path"
    chown -R "${target_user}:${target_group}" "$path"
  else
    log "Ownership OK: $path ($owner:$group)"
  fi
}

create_dir_and_link() {
  local src="$1" dest="$2" owner="$3" mode="$4"

  log "Setup data directory and symlink: ${src} -> ${dest}";

  mkdir -p "$src"
  chown "$owner" "$src"
  chmod "$mode" "$src"

  local dest_dir
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"
  chown "$owner" "$dest_dir"
  chmod "$mode" "$dest_dir"

  ln -sfn "$src" "$dest"
}

create_file_and_link() {
  local src="$1" dest="$2" owner="$3" mode="$4"
  
  log "Setup data file and symlink: ${src} -> ${dest}";

  touch "$src"
  chown "$owner" "$src"
  chmod "$mode" "$src"

  ln -sfn "$src" "$dest"
}

log "Checking Data Folder"
ANSVIL_USER_DATA_DIR="${ANSVIL_USER_HOME}/.data"
if [ ! -d "$ANSVIL_USER_DATA_DIR" ]; then
  log "Missing data directory: $ANSVIL_USER_DATA_DIR"
  exit 1
fi

for data_dir in \
  ".local/share/code-server" \
  ".ssh" \
  ".config"; do
    create_dir_and_link "${ANSVIL_USER_DATA_DIR}/${data_dir}" "${ANSVIL_USER_HOME}/${data_dir}" "${ANSVIL_USER}:${ANSVIL_USER}" 755
done


for data_file in \
  ".gitconfig" \
  ".bash_history"; do
    create_file_and_link "${ANSVIL_USER_DATA_DIR}/${data_file}" "${ANSVIL_USER_HOME}/${data_file}" "${ANSVIL_USER}:${ANSVIL_USER}" 600
done



# === Ownership fix ===
for path in \
  "$ANSVIL_PROJECTS_PATH" \
  "$ANSVIL_USER_HOME/.data" \
  "$ANSVIL_USER_HOME/.local" \
  "$ANSVIL_USER_HOME/.config" \
  "$ANSVIL_USER_HOME/.bashrc.d" \
  "$ANSVIL_USER_HOME/.bash_history"; do
    fix_ownership_if_needed "$path" "${ANSVIL_USER}:${ANSVIL_USER}"
done

log "Running original entrypoint"
/entrypoint.sh "$@"
