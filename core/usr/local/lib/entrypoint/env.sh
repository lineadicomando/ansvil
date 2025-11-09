routine_init_env() {
  
  local env_path="/etc/profile.d/env.sh"
  env | grep -E '^(ANSVIL_|SEMAPHORE_|CODE_)' | sed 's/^/export /' > "${env_path}"
  echo "PATH=\"\$PATH:/usr/local/bin\"" >> "${env_path}"
  chmod 644 "${env_path}"

  TZ="${TZ:-UTC}"

  if [ -f "/usr/share/zoneinfo/$TZ" ]; then
      ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
  else
      log ERROR "Invalid timezone specified: $TZ."
  fi

}