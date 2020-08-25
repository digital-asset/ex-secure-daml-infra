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

if [ ! -f certs/jwt/navigator.token ] ; then
  ./get-navigator-token.sh
fi

daml navigator server \
  --cacrt certs/intermediate/certs/ca-chain.cert.pem \
  --tls $CLIENT_CERT_PARAM \
  --access-token-file certs/jwt/navigator.token \
  ledger.$DOMAIN 6865
