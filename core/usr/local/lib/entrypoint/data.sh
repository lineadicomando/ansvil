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
  # === Ownership fix ===
  for path in "${ANSVIL_USER_HOME}"; do
      fix_ownership_if_needed "$path" "${ANSVIL_USER}:${ANSVIL_USER}"
  done

}