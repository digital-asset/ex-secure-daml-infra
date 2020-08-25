#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set +e 

source env.sh

# Testing TLS
#
# https://www.poftut.com/use-openssl-s_client-check-verify-ssltls-https-webserver/
# https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html
# https://testssl.sh/
#

PATH=/usr/local/opt/openssl@1.1/bin:$PATH

echo "Testing database"
echo | openssl s_client -connect "db.$DOMAIN:5432" -CAfile certs/intermediate/certs/ca-chain.cert.pem --starttls postgres -tls1_2

echo ""
echo "Testing web server"
echo | openssl s_client -connect "web.$DOMAIN:443" -CAfile certs/intermediate/certs/ca-chain.cert.pem -tls1_2

echo ""
echo "Testing sandbox"
echo | openssl s_client -connect "ledger.$DOMAIN:6865" -CAfile certs/intermediate/certs/ca-chain.cert.pem -tls1_2

