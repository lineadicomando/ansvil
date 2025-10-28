#!/bin/bash
CERT_BASE_PATH=/etc/ssl
V3_EXT="${CERT_BASE_PATH}/v3.ext"

cat "$V3_EXT" | grep "DNS." | cut -d" " -f3