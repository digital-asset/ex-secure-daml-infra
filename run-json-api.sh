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

if [ ! -f http-json-1.17.1.jar ]; then
   wget -q https://github.com/digital-asset/daml/releases/download/v1.17.1/http-json-1.17.1.jar
fi


java -jar http-json-1.17.1.jar --ledger-host ledger.$DOMAIN \
  --ledger-port 6865 --address 127.0.0.1 \
  --http-port 7575 --max-inbound-message-size 4194304 \
  --package-reload-interval 5s \
  --query-store-jdbc-config "driver=org.postgresql.Driver,url=jdbc:postgresql://db.$DOMAIN:5432/postgres?ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/client/client1.$DOMAIN.cert.der&sslkey=$ROOTDIR/certs/client/client1.$DOMAIN.key.der,user=postgres,password=ChangeDefaultPassword!,start-mode=create-only" \
  --cacrt ./certs/intermediate/certs/ca-chain.cert.pem $CLIENT_CERT_PARAM \
  --tls \
  --access-token-file=certs/jwt/json.token

java -jar http-json-1.17.1.jar --ledger-host ledger.$DOMAIN \
  --ledger-port 6865 --address 127.0.0.1 \
  --http-port 7575 --max-inbound-message-size 4194304 \
  --package-reload-interval 5s \
  --query-store-jdbc-config "driver=org.postgresql.Driver,url=jdbc:postgresql://db.$DOMAIN:5432/postgres?ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/client/client1.$DOMAIN.cert.der&sslkey=$ROOTDIR/certs/client/client1.$DOMAIN.key.der,user=postgres,password=ChangeDefaultPassword!,create-schema=false" \
  --cacrt ./certs/intermediate/certs/ca-chain.cert.pem $CLIENT_CERT_PARAM \
  --tls \
  --access-token-file=certs/jwt/json.token
