fix_ownership_if_needed() {
  local path="$1"
  local target_usergroup="$2"

  log INFO "Checking ownership for: $path"

  if [ ! -e "$path" ]; then
    log INFO "Skipping (not found): $path"
    return
  fi

  local owner group
  owner=$(stat -c '%U' "$path")
  group=$(stat -c '%G' "$path")
  local target_user="${target_usergroup%%:*}"
  local target_group="${target_usergroup##*:}"

  if [[ "$owner" != "$target_user" || "$group" != "$target_group" ]]; then
    log INFO "Fixing ownership of: $path"
    chown -R "${target_user}:${target_group}" "$path"
  else
    log INFO "Ownership OK: $path ($owner:$group)"
  fi
}

create_dir_and_link() {
  local src="$1" dest="$2" owner="$3" mode="$4"

  log INFO "Setup data directory and symlink: ${src} -> ${dest}";

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
  
  log INFO "Setup data file and symlink: ${src} -> ${dest}";

  touch "$src"
  chown "$owner" "$src"
  chmod "$mode" "$src"

  ln -sfn "$src" "$dest"
}

routine_init_data_folder() {

  log INFO "Checking Data Folder"
  ANSVIL_USER_DATA_DIR="${ANSVIL_USER_HOME}/.data"
  if [ ! -d "$ANSVIL_USER_DATA_DIR" ]; then
    die "Missing data directory: $ANSVIL_USER_DATA_DIR"
  fi

  for data_dir in \
    ".local/share/code-server" \
    ".ssh" \
    ".config"; do
      create_dir_and_link "${ANSVIL_USER_DATA_DIR}/${data_dir}" "${ANSVIL_USER_HOME}/${data_dir}" "${ANSVIL_USER}:${ANSVIL_USER}" 755
  done

  for data_file in \
    ".git-credentials" \
    ".gitconfig" \
    ".bash_history"; do
      create_file_and_link "${ANSVIL_USER_DATA_DIR}/${data_file}" "${ANSVIL_USER_HOME}/${data_file}" "${ANSVIL_USER}:${ANSVIL_USER}" 600
  done

  # === Ownership fix ===
  for path in \
    "${ANSVIL_PROJECTS_PATH}" \
    "${ANSVIL_USER_HOME}/.data" \
    "${ANSVIL_USER_HOME}/.local" \
    "${ANSVIL_USER_HOME}/.config" \
    "${ANSVIL_USER_HOME}/.bashrc.d" \
    "${ANSVIL_USER_HOME}/.git-credentials" \
    "${ANSVIL_USER_HOME}/.gitconfig" \
    "${ANSVIL_USER_HOME}/.ssh" \
    "${ANSVIL_USER_HOME}/.bash_history"; do
      fix_ownership_if_needed "$path" "${ANSVIL_USER}:${ANSVIL_USER}"
  done

}