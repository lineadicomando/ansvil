#!/usr/bin/env bash
set -euo pipefail

ANSVIL_STATUS_FILE="${ANSVIL_STATUS_FILE:-/status/state.json}"

routine_init_status() {
    mkdir -p "$(dirname "$ANSVIL_STATUS_FILE")"
    set_status initializing true phase init msg "System initialization"
}

__is_boolean() {
    [[ "${1,,}" =~ ^(true|false|0|1|yes|no|y|n)$ ]]
}

__is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

set_status() {

    [[ ! -f "$ANSVIL_STATUS_FILE" ]] && echo '{}' > "$ANSVIL_STATUS_FILE"

    local jq_expr="{"
    while [[ $# -gt 0 ]]; do
        if [[ $jq_expr != "{" ]]; then
          jq_expr+=","
        fi
        key=$1; shift
        val=$1; shift
        if __is_boolean "${val}" || __is_number "${val}"; then
          jq_expr+="${key}:${val}"
        else 
          jq_expr+="${key}:\"${val}\""
        fi
    done
    jq_expr+="}"

    log DEBUG "$jq_expr"
    jq "$jq_expr" "$ANSVIL_STATUS_FILE" > "${ANSVIL_STATUS_FILE}.tmp" && mv "${ANSVIL_STATUS_FILE}.tmp" "$ANSVIL_STATUS_FILE"
    log INFO Status updated: $(cat $ANSVIL_STATUS_FILE)
}
