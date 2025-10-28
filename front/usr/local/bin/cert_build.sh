#!/bin/bash

source /usr/local/bin/cert_env.sh

openssl x509 -req -in "$SERVER_CSR" -CA "$ROOT_CA_PEM" -CAkey "$ROOT_CA_KEY" -CAcreateserial -out "$SERVER_CRT" -days ${SSL_DAYS:-182500} -sha256 -extfile "$V3_EXT"
