#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then

  GEORGE_CLIENT_ID="george123456"
  GEORGE_CLIENT_SECRET=`cat accounts.json | jq ."$GEORGE_CLIENT_ID".secret  | tr -d '"'`

  # REQUESTS_CA_BUNDLE="./certs/intermediate/certs/ca-chain.cert.pem" python3 bot/bot.py \
  python3 bot/bot.py \
   "George" \
   "ex-secure-daml-infra" \
   "https://ledger.$DOMAIN:6865" \
   "./certs/intermediate/certs/ca-chain.cert.pem" \
   "./certs/client/client1.acme.com.cert.pem" \
   "./certs/client/client1.acme.com.key.pem" \
   $GEORGE_CLIENT_ID \
   $GEORGE_CLIENT_SECRET \
   "https://auth.$DOMAIN:4443/oauth/token" \
   "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" \
   "https://daml.com/ledger-api"
else
  python3 bot/bot.py \
   "George" \
   "ex-secure-daml-infra" \
   "https://ledger.$DOMAIN:6865" \
   "./certs/intermediate/certs/ca-chain.cert.pem" \
   "./certs/client/client1.acme.com.cert.pem" \
   "./certs/client/client1.acme.com.key.pem" \
   $GEORGE_CLIENT_ID \
   $GEORGE_CLIENT_SECRET \
   "https://digitalasset-dev.auth0.com/oauth/token" \
   "https://daml.com/ledger-api"
fi
