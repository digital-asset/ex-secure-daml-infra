#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

CLIENT_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_PARAM="--pem $(pwd)/certs/client/client1.$DOMAIN.key.pem --crt $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
fi

./get-bob-token.sh

AUTH_TOKEN=`cat "certs/jwt/bob.token"`
./decode-jwt.sh "certs/jwt/bob.token"

daml trigger --dar ./dist/ex-secure-daml-infra-0.0.1.dar \
  --trigger-name BobTrigger:rejectTrigger \
  --ledger-host ledger.$DOMAIN --ledger-port 6865 \
  --ledger-party Bob \
  --application-id "ex-secure-daml-infra" \
  --access-token-file=./certs/jwt/bob.token \
  --tls $CLIENT_CERT_PARAM \
  --cacrt "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" 
