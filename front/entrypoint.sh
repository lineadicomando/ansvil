#!/bin/bash

echo ">> Init SSL Certs..."
/usr/local/bin/cert_init.sh

echo ">> Starting Nginx..."
exec nginx -g "daemon off;"
