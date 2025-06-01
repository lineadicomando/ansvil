# === Logging utility ===

log() {
  local level="$1"
  shift
  local color output_fd

  case "$level" in
    INFO)
      color="\033[1;32m"
      output_fd=1
      ;;
    WARN)
      color="\033[1;33m"
      output_fd=1
      ;;
    ERROR)
      color="\033[1;31m"
      output_fd=2
      ;;
    *)
      color="\033[0m"
      output_fd=1
      ;;
  esac

  echo -e "[Entrypoint] ${color}[$level]\033[0m $*" >&${output_fd}
}


die() {
  local msg="${*:-"Unknown error"}"
  log ERROR "$msg"
  exit 1
}