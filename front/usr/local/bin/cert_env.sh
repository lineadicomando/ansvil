#!/bin/bash

CERT_BASE_PATH=/etc/cert
ROOT_CA_KEY="${CERT_BASE_PATH}/rootCA.key"
ROOT_CA_PEM="${CERT_BASE_PATH}/rootCA.pem"
SERVER_CSR_CNF="${CERT_BASE_PATH}/server.csr.cnf"
SERVER_CSR="${CERT_BASE_PATH}/server.csr"
SERVER_KEY="${CERT_BASE_PATH}/server.key"
SERVER_CRT="${CERT_BASE_PATH}/server.crt"
V3_EXT="${CERT_BASE_PATH}/v3.ext"