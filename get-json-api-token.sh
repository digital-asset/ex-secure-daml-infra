#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then
   echo "Using local signing of JWT"
   exit 0
fi

if [ ! -d certs/jwt ] ; then
  mkdir certs/jwt
fi

curl -s --request POST \
  --url https://digitalasset-dev.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data "{ \"client_id\": \"$JSON_CLIENT_ID\", \"client_secret\": \"$JSON_CLIENT_SECRET\", \"audience\": \"https://daml.com/ledger-api\", \"grant_type\": \"client_credentials\" }" | jq .access_token  | tr -d '"' > "$(pwd)/certs/jwt/json.token"



