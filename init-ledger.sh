#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

CLIENT_CERT_PARAM=""
CURL_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_PARAM="--pem $(pwd)/certs/client/client1.$DOMAIN.key.pem --crt $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
  CURL_CERT_PARAM="--key $(pwd)/certs/client/client1.$DOMAIN.key.pem --cert $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
fi

./get-m2m-token.sh

AUTH_TOKEN=`cat "certs/jwt/m2m.token"`
./decode-jwt.sh "certs/jwt/m2m.token"

echo ""
echo "Getting all current parties"
RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://server.$DOMAIN:8000/v1/parties`

echo $RESULT 
echo $RESULT | jq .

 echo ""
echo "Getting all current DAR packages"
RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://server.$DOMAIN:8000/v1/packages`
echo $RESULT | jq .

daml script --dar ./dist/ex-secure-daml-infra-0.0.1.dar \
  --script-name Main:setup \
  --ledger-host ledger.acme.com --ledger-port 6865 \
  --access-token-file=./certs/jwt/m2m.token \
  --application-id "ex-secure-daml-infra" \
  --tls $CLIENT_CERT_PARAM \
  --cacrt "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem"

RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM\
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://server.$DOMAIN:8000/v1/parties`
echo $RESULT | jq .

