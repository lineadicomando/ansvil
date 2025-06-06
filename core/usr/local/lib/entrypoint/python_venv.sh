#!/bin/bash

routine_activate_python_venv() {

  log INFO "Activating Python virtual environment"
  
  local V="0.1"
  local block_start="# >>> VEnv activation ${V} >>>"
  local block_end="# <<< VEnv activation <<<"
  local bashrc="${ANSVIL_USER_HOME}/.bashrc"
  local venv_block
  local needs_update=0

  if [ -z "${ANSVIL_USER_HOME}" ]; then
    log ERROR "ANSVIL_USER_HOME is not set."
    return 1
  fi

  venv_block=$(cat <<EOF
${block_start}
if [ -f /venv/bin/activate ]; then
    source /venv/bin/activate
fi
${block_end}
EOF
)

  if [ ! -f "${bashrc}" ]; then
    if [ -f /etc/skel/.bashrc ]; then
      cp -n /etc/skel/.bashrc "${bashrc}"
    else
      echo "# Created by routine_activate_python_venv" >> "${bashrc}"
      touch "${bashrc}"
    fi
  fi

  if grep -Fq "${block_start}" "${bashrc}"; then
    log INFO "VEnv activation block (version ${V}) already present. No changes needed."
    return 0
  fi

  needs_update=1

  if [ ${needs_update} -eq 1 ]; then
    log INFO "Updating VEnv activation block to version ${V}..."

    # Backup the existing .bashrc file
    cp "${bashrc}" "${bashrc}.bak.$(date +%s)"

    log INFO "Backup created at ${bashrc}.bak.$(date +%s)"

    # Remove old VEnv activation block if it exists
    sed -i '/# >>> VEnv activation .* >>>/,/# <<< VEnv activation <<</d' "${bashrc}"
    log INFO "Old VEnv activation block removed."

    # Append the new VEnv activation block
    echo -e "\n${venv_block}" >> "${bashrc}"

    log INFO "Block version ${V} added successfully."
  fi
}
