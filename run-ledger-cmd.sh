#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

# Start Navigator Server

CLIENT_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_PARAM="--pem $(pwd)/certs/client/client1.$DOMAIN.key.pem --crt $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
fi

./get-m2m-token.sh

daml ledger \
  --cacrt certs/intermediate/certs/ca-chain.cert.pem \
  --tls $CLIENT_CERT_PARAM \
  --access-token-file certs/jwt/m2m.token \
  --host ledger.acme.com --port 6865 $1
