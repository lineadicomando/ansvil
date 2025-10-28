#!/bin/bash

source /usr/local/bin/cert_env.sh

cat "$V3_EXT" | grep "DNS." | cut -d" " -f3