#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

# Start JSON API Server

CLIENT_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_PARAM="--pem $(pwd)/certs/client/client1.$DOMAIN.key.pem --crt $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
fi

./get-json-api-token.sh

export TRIGGER_SERVICE_SECRET_KEY="SecurityIsImportant!"

daml trigger-service init-db --ledger-host ledger.$DOMAIN \
  --ledger-port 6865 \
  --jdbc "driver=org.postgresql.Driver,url=jdbc:postgresql://db.$DOMAIN:5432/postgres?&ssl=true,user=postgres,password=ChangeDefaultPassword!,createSchema=false" 
  

#  --cacrt ./certs/intermediate/certs/ca-chain.cert.pem $CLIENT_CERT_PARAM \
#  --access-token-file=certs/jwt/json.token

