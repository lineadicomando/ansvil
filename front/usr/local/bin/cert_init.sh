#!/bin/bash

source /usr/local/bin/cert_env.sh

SUBJECT="/C=${SSL_C:-US}/ST=${SSL_ST:-Unknown}/L=${SSL_L:-City}/O=${SSL_O:-Org}/CN=${SSL_CN:-localhost}"

if [ ! -d "$CERT_BASE_PATH" ]; then
	mkdir -p "$CERT_BASE_PATH"
fi

if [ ! -f "$ROOT_CA_KEY" ]; then
	openssl genrsa -out "$ROOT_CA_KEY" 2048
fi

if [ ! -f "$ROOT_CA_PEM" ]; then
	openssl req -x509 -new -nodes -key "$ROOT_CA_KEY" -sha256 -days "${SSL_DAYS:-182500}" -out "$ROOT_CA_PEM" -subj "$SUBJECT"
fi

if [ ! -f "$SERVER_CSR_CNF" ]; then
	cat > "$SERVER_CSR_CNF" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
[dn]
C=${SSL_C:-US}
ST=${SSL_ST:-Unknown}
L=${SSL_L:-City}
O=${SSL_O:-Org}
OU=${SSL_CN:-OrgUni}
emailAddress=${SSL_EMAIL:-hello@example.com}
CN = ${SSL_CN:-localhost}
EOF
fi

if [ ! -f "$V3_EXT" ]; then
	cat > "$V3_EXT" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1 = localhost
EOF
fi

if [ ! -f "$SERVER_CSR" ] || [ ! -f "$SERVER_KEY" ]; then
	openssl req -new -sha256 -nodes -out "$SERVER_CSR" -newkey rsa:2048 -keyout "$SERVER_KEY" -config "$SERVER_CSR_CNF"
fi

if [ ! -f "$SERVER_CRT" ]; then
	/usr/local/bin/cert_build.sh
	# openssl x509 -req -in "$SERVER_CSR" -CA "$ROOT_CA_PEM" -CAkey "$ROOT_CA_KEY" -CAcreateserial -out "$SERVER_CRT" -days ${SSL_DAYS:-182500} -sha256 -extfile "$V3_EXT"
fi
