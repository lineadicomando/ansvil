routine_init_sshd() {
    ssh-keygen -A
}


routine_start_sshd() {
  log INFO "Starting sshd..."

  /usr/sbin/sshd -D -e &
  SSHD_PID=$!

  # Verifica se il processo è partito
  if ! kill -0 "$SSHD_PID" 2>/dev/null; then
    die "sshd process failed to start (PID=$SSHD_PID)"
  fi
}
