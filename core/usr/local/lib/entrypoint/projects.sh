routine_init_projects_folder() {
  if [[ ! -d "${ANSVIL_DEFAULT_PROJECTS_PATH}" ]]; then
    log INFO "Creating project directory: ${ANSVIL_DEFAULT_PROJECTS_PATH}"
    mkdir -p "${ANSVIL_DEFAULT_PROJECTS_PATH}"
    chown "${ANSVIL_USER}:${ANSVIL_USER}" "${ANSVIL_DEFAULT_PROJECTS_PATH}"
  fi
}
