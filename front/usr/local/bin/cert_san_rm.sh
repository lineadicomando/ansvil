#!/usr/bin/env bash
set -Eeuo pipefail

source /usr/local/bin/cert_env.sh

# Safe IFS for arrays/lines
IFS=$'\n\t'

# === Config / prerequisites ===================================================
: "${V3_EXT:?Undefined variable V3_EXT (path to v3.ext file))}"

CERT_BUILD=${CERT_BUILD:-/usr/local/bin/cert_build.sh}
NGINX_SERVICE=${NGINX_SERVICE:-nginx}

# === Args validation ==========================================================
if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <dns-name>"
  exit 2
fi

TARGET_DNS=$1

# Relaxed regex that allows wildcards and underscores (common in SANs)
# Valid examples: example.com, sub.example.com, *.example.com, _acme-challenge.example.com
if [[ ! $TARGET_DNS =~ ^(\*\.)?([_0-9a-z-]+\.)+[0-9a-z-]+$ ]]; then
  echo "Error: '$TARGET_DNS' is not a valid DNS for SAN"
  exit 3
fi

# === Atomic backup + restore on errors =======================================
backup="$(mktemp "${V3_EXT}.bk.XXXXXX")"
tmpout="$(mktemp "${V3_EXT}.tmp.XXXXXX")"
trap 'echo "Error, restoring original file..."; mv -f -- "$backup" "$V3_EXT" 2>/dev/null || true; rm -f -- "$tmpout"; exit 1' ERR INT TERM

cp -f -- "$V3_EXT" "$backup"

# === Extract existing names while preserving order ============================
# - Copy all NON-DNS.* lines to the temporary file (preserves the rest of the config)
# - Extract the list of DNS.* = name (only the name)
mapfile -t existing_dns < <(awk '
  BEGIN{IGNORECASE=0}
  /^[[:space:]]*DNS\.[0-9]+[[:space:]]*=/ {
    sub(/^[^=]*=[[:space:]]*/,"")
    gsub(/^[[:space:]]+|[[:space:]]+$/,"")
    print
    next
  }
  { print > "'"$tmpout"'" }
' "$V3_EXT")

# === Build filtered list (remove target), keep order, no duplicates ===========
declare -A seen=()
dns_list=()
removed=0

for name in "${existing_dns[@]}"; do
  [[ -z $name ]] && continue
  # Skip exact matches (case-sensitive) of the target
  if [[ $name == "$TARGET_DNS" ]]; then
    removed=1
    continue
  fi
  # Keep first occurrence only (dedup)
  if [[ -z ${seen["$name"]+x} ]]; then
    seen["$name"]=1
    dns_list+=("$name")
  fi
done

# If nothing was removed, abort changes and keep original file
if [[ $removed -eq 0 ]]; then
  rm -f -- "$tmpout"
  rm -f -- "$backup"
  echo "SAN '$TARGET_DNS' not found: no changes"
  exit 0
fi

# === Write DNS.N lines in order without gaps ==================================
i=1
for name in "${dns_list[@]}"; do
  printf 'DNS.%d = %s\n' "$i" "$name" >> "$tmpout"
  ((i++))
done

# === Atomic replace of the file ===============================================
mv -f -- "$tmpout" "$V3_EXT"
rm -f -- "$backup"

# === Rebuild certificate and reload Nginx (only if changes were made) =========
if [[ -x "$CERT_BUILD" ]]; then
  "$CERT_BUILD"
else
  echo "Warning: Certificate build script not found: $CERT_BUILD"
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl reload "$NGINX_SERVICE"
else
  service "$NGINX_SERVICE" reload
fi

echo "Removed DNS SAN: $TARGET_DNS"
