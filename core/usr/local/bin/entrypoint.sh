#!/bin/bash
set -euo pipefail

# === Environment validation ===
: "${ANSVIL_USER:?ANSVIL_USER not set}"
: "${ANSVIL_USER_HOME:?ANSVIL_USER_HOME not set}"
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
log INFO "common.sh loaded"

source /usr/local/lib/entrypoint/hooks.sh
log INFO "hooks.sh loaded"

source /usr/local/lib/entrypoint/env.sh
log INFO "env.sh loaded"

source /usr/local/lib/entrypoint/python_venv.sh
log INFO "python_venv.sh loaded"

source /usr/local/lib/entrypoint/data.sh
log INFO "data.sh loaded"

source /usr/local/lib/entrypoint/projects.sh
log INFO "projects.sh loaded"

source /usr/local/lib/entrypoint/code-server.sh
log INFO "code-server.sh loaded"

source /usr/local/lib/entrypoint/semaphore-ui.sh
log INFO "semaphore-ui.sh loaded"

# === Init ===

routine_init_venv

routine_init_data_folder

routine_init_env

routine_init_hooks

routine_activate_python_venv

routine_init_projects_folder

# === Initialize services ===

routine_init_code_server

routine_init_semaphore_ui

# === Run entrypoint hooks ===

run_entrypoint_hooks init root
run_entrypoint_hooks init user

trap _term SIGTERM SIGINT # defined in hooks.sh

# === Start services ===

routine_start_code_server
routine_start_semaphore_ui

# === Run entrypoint hooks ===

run_entrypoint_hooks start root
run_entrypoint_hooks start user

# === Wait for services to finish ===
wait "$CODE_SERVER_PID" "$SEMAPHORE_PID"