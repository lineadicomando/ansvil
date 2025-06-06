# === Function: Entrypoint Hooks ===
run_entrypoint_hooks() {
  local stage="$1"
  local mode="$2"
  local dir="/usr/local/entrypoint.d/$mode"
  local lib_path="/usr/local/lib/entrypoint"

  [ -d "$dir" ] || return

  for f in "$dir"/*-"$stage"-*.sh; do
    [ -f "$f" ] || continue
    log INFO "[$stage/$mode] Executing: $f"

    case "$mode" in
      root)
        source /usr/local/lib/entrypoint/common.sh
        source "$f"
        ;;
      user)
        su - "$ANSVIL_USER" -c "bash -c 'source ${lib_path}/env.sh; source ${lib_path}/common.sh; source \"$f\"'"
        ;;
    esac

    local status=$?
    if [ $status -ne 0 ]; then
      log ERROR "[$stage/$mode] Hook '$f' exited with status $status"
    fi
  done
}


routine_init_hooks() {
  # local lib_path="/usr/local/lib/entrypoint"
  for role in root user; do
    src_dir="/usr/local/share/templates/entrypoint.d/${role}"
    dst_dir="/usr/local/entrypoint.d/${role}"

    if [ -d "$src_dir" ]; then
      mkdir -p "$dst_dir"

      for template_file in "$src_dir"/*.sh; do
        [ -f "$template_file" ] || continue
        filename="$(basename "$template_file")"
        target_file="${dst_dir}/${filename}"

        if [ ! -f "$target_file" ]; then
          log INFO "Installing missing hook: $target_file"
          cp "$template_file" "$target_file"
          chmod +x "$target_file"
        else
          log INFO "Hook already exists, skipping: $target_file"
        fi
      done
    fi
  done
  chown -R "${ANSVIL_USER}:${ANSVIL_USER}" /usr/local/entrypoint.d
  # log INFO "Entrypoint env file initialized"
  # env | grep -E '^(ANSVIL_|SEMAPHORE_)' | sed 's/^/export /' > "${lib_path}/env.sh"
  # chmod 644 "${lib_path}/env.sh"
}


# === Signal handling ===
_term() {
  log INFO "Caught SIGTERM, stopping services..."
  kill -TERM "${CODE_SERVER_PID}" "${SEMAPHORE_PID}" 2>/dev/null
  wait "${CODE_SERVER_PID}" "${SEMAPHORE_PID}"
  log INFO "All services stopped"

  run_entrypoint_hooks exit root
  run_entrypoint_hooks exit user
  exit 0
}