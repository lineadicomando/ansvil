#!/bin/bash

log INFO "[user/init] Install Code-Server Extensions"

# Define extensions to ensure are installed
extensions=(
  redhat.ansible
)

# Get the list of already installed extensions
installed=$(code-server --list-extensions)

for ext in "${extensions[@]}"; do
  if echo "$installed" | grep -q "^${ext}$"; then
    log INFO "[user/init] Extension '$ext' already installed, skipping."
  else
    log INFO "[user/init] Installing extension '$ext'"
    code-server --install-extension "$ext" --force
  fi
done
