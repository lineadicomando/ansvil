#!/bin/bash
set -euo pipefail

# === Environment validation ===
: "${ANSVIL_USER:?ANSVIL_USER not set}"
: "${ANSVIL_USER_HOME:?ANSVIL_USER_HOME not set}"
: "${ANSVIL_PROJECTS_PATH:?ANSVIL_PROJECTS_PATH not set}"
: "${SEMAPHORE_DB_HOST:?}"
: "${SEMAPHORE_DB_PORT:?}"
: "${SEMAPHORE_DB_NAME:?}"
: "${SEMAPHORE_DB_USER:?}"
: "${SEMAPHORE_DB_PASS:?}"
: "${SEMAPHORE_ADMIN_USER:?}"
: "${SEMAPHORE_ADMIN_NAME:?}"
: "${SEMAPHORE_ADMIN_EMAIL:?}"
: "${SEMAPHORE_ADMIN_DEFAULT_PASSWORD:?}"
: "${CODE_SERVER_DEFAULT_PASSWORD:?}"

# === Load common functions and routines ===
source /usr/local/lib/entrypoint/common.sh
source /usr/local/lib/entrypoint/hooks.sh
source /usr/local/lib/entrypoint/data.sh
source /usr/local/lib/entrypoint/projects.sh
source /usr/local/lib/entrypoint/code-server.sh
source /usr/local/lib/entrypoint/semaphore-ui.sh

routine_init_data_folder

routine_init_hooks

chmod 755 "${ANSVIL_USER_HOME}"

run_entrypoint_hooks init root
run_entrypoint_hooks init user

routine_init_projects_folder

routine_init_code_server

routine_init_semaphore_ui

trap _term SIGTERM SIGINT # defined in hooks.sh

chmod 555 "${ANSVIL_USER_HOME}"

# === Start services ===

routine_start_code_server
routine_start_semaphore_ui

run_entrypoint_hooks start root
run_entrypoint_hooks start user

wait "$CODE_SERVER_PID" "$SEMAPHORE_PID"