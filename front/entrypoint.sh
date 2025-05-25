#!/bin/sh

CERT_DIR="/etc/ssl/certs"
CERT_PATH="${CERT_DIR}/nginx-selfsigned.crt"

KEY_DIR="/etc/ssl/private"
KEY_PATH="${KEY_DIR}/nginx-selfsigned.key"

if [ ! -d "${CERT_DIR}" ]; then
    mkdir -p "${CERT_DIR}"
    chmod 750 "${CERT_DIR}"
fi

if [ ! -d "${KEY_DIR}" ]; then
    mkdir -p "${KEY_DIR}"
    chmod 750 "${KEY_DIR}"
fi

if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo ">> Generating self-signed SSL certificate..."

    SUBJECT="/C=${SSL_C:-US}/ST=${SSL_ST:-Unknown}/L=${SSL_L:-City}/O=${SSL_O:-Org}/CN=${SSL_CN:-localhost}"
    echo "$SUBJECT"

    openssl req -x509 -nodes -days "${SSL_DAYS:-365}" -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "$SUBJECT" \
        -config /etc/ssl/openssl.cnf || {
            echo ">> ERROR: Failed to generate certificate"
            exit 1
        }
else
    echo ">> SSL certificate already exists."
fi

echo ">> Starting Nginx..."
exec nginx -g "daemon off;"
