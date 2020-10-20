#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then

  GEORGE_CLIENT_ID="george123456"
  GEORGE_CLIENT_SECRET=`cat accounts.json | jq ."$GEORGE_CLIENT_ID".secret  | tr -d '"'`

  # REQUESTS_CA_BUNDLE="./certs/intermediate/certs/ca-chain.cert.pem" python3 bot/bot.py \
  python3 bot/bot.py \
   --application-name "ex-secure-daml-infra" \
   --url "https://ledger.$DOMAIN:6865" \
   --cert-key-file "./certs/client/client1.acme.com.key.pem" \
   --cert-file "./certs/client/client1.acme.com.cert.pem" \
   --ca-file "./certs/intermediate/certs/ca-chain.cert.pem" \
   --oauth-client-id $GEORGE_CLIENT_ID \
   --oauth-client-secret $GEORGE_CLIENT_SECRET \
   --oauth-token-uri "https://auth.$DOMAIN:4443/oauth/token" \
   --oauth-ca-file "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" \
   --oauth-audience "https://daml.com/ledger-api"
else
  python3 bot/bot.py \
   --application-name "ex-secure-daml-infra" \
   --url "https://ledger.$DOMAIN:6865" \
   --cert-key-file "./certs/client/client1.acme.com.key.pem" \
   --cert-file "./certs/client/client1.acme.com.cert.pem" \
   --ca-file "./certs/intermediate/certs/ca-chain.cert.pem" \
   --oauth-client-id $GEORGE_CLIENT_ID \
   --oauth-client-secret $GEORGE_CLIENT_SECRET \
   --oauth-token-uri "https://digitalasset-dev.auth0.com/oauth/token" \
   --oauth-audience "https://daml.com/ledger-api"
fi
