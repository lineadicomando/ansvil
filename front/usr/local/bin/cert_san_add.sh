#!/usr/bin/env bash
set -Eeuo pipefail

source /usr/local/bin/cert_env.sh

# Imposta una IFS sicura per i cicli su array/righe
IFS=$'\n\t'

# === Config / prerequisiti ====================================================
: "${V3_EXT:?Undefined variable V3_EXT (path to v3.ext file))}"

CERT_BUILD=${CERT_BUILD:-/usr/local/bin/cert_build.sh}
NGINX_SERVICE=${NGINX_SERVICE:-nginx}

# Convalida argomenti
if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <dns-name>"
  exit 2
fi

NEW_DNS=$1

# Relaxed regex that allows wildcards and underscores (common in SANs)
# Valid examples: example.com, sub.example.com, *.example.com, _acme-challenge.example.com
if [[ ! $NEW_DNS =~ ^(\*\.)?([_0-9a-z-]+\.)+[0-9a-z-]+$ ]]; then
  echo "Error: '$NEW_DNS' is not a valid DNS for SAN"
  exit 3
fi

# === Backup atomico + ripristino su errori ====================================
backup="$(mktemp "${V3_EXT}.bk.XXXXXX")"
tmpout="$(mktemp "${V3_EXT}.tmp.XXXXXX")"
trap 'echo "Error, restore file..."; mv -f -- "$backup" "$V3_EXT" 2>/dev/null || true; rm -f -- "$tmpout"; exit 1' ERR INT TERM

cp -f -- "$V3_EXT" "$backup"

# === Extract existing names while preserving order ==============================
# - Copy all NON-DNS.* lines to the temporary file (preserves the rest of the config)
# - Extract the list of DNS.* = name (only the name)
mapfile -t existing_dns < <(awk '
  BEGIN{IGNORECASE=0}
  # DNS.N lines = name -> extract "name"
  /^[[:space:]]*DNS\.[0-9]+[[:space:]]*=/ {
    # take everything after the first "=" and trim
    sub(/^[^=]*=[[:space:]]*/,"")
    gsub(/^[[:space:]]+|[[:space:]]+$/,"")
    print
    next
  }
  # Everything else goes into the preserved output file
  { print > "'"$tmpout"'" }
' "$V3_EXT")

# === Normalization, dedup, and append of the new name =============================
# Case-sensitive dedup; if it's already present, we don't add it again.
declare -A seen=()
dns_list=()

for name in "${existing_dns[@]}"; do
  [[ -z $name ]] && continue
  if [[ -z ${seen["$name"]+x} ]]; then
    seen["$name"]=1
    dns_list+=("$name")
  fi
done

if [[ -z ${seen["$NEW_DNS"]+x} ]]; then
  dns_list+=("$NEW_DNS")
  added=1
else
  added=0
fi

# === Writing new DNS.N lines in order and without holes =================
i=1
for name in "${dns_list[@]}"; do
  printf 'DNS.%d = %s\n' "$i" "$name" >> "$tmpout"
  ((i++))
done

# === Atomic File Replacement ================================================
mv -f -- "$tmpout" "$V3_EXT"
rm -f -- "$backup"

# === Build certificate and reload Nginx (if present) ============================
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

if [[ $added -eq 1 ]]; then
	echo "Added DNS SAN: $NEW_DNS"
else
	echo "The SAN '$NEW_DNS' already exists: no changes"
fi
