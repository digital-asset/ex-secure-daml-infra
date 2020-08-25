#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# https://prefetch.net/blog/2020/04/22/using-grpcurl-to-interact-with-grpc-applications/
# https://bionic.fullstory.com/tale-of-grpcurl/

source env.sh

CLIENT_CERT_PARAM=""
CURL_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_PARAM="--pem $(pwd)/certs/client/client1.$DOMAIN.key.pem --crt $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
  CURL_CERT_PARAM="--key $(pwd)/certs/client/client1.$DOMAIN.key.pem --cert $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
fi

if [ ! -f certs/jwt/m2m.token ] ; then
   ./get-m2m-token.sh
fi

# Prove GRPC is up on TLS
echo "" 
echo "Get list of services via reflection"
JWT=`cat certs/jwt/m2m.token`

echo "" 
echo "Testing direct to Ledger..."
grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 list

echo "" 
echo "Testing via Envoy..."
grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" envoy.$DOMAIN:10000 list


echo ""
echo "Describe a service"
grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 describe com.daml.ledger.api.v1.PackageService

 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 describe com.daml.ledger.api.v1.ListPackagesRequest

echo ""
 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 describe com.daml.ledger.api.v1.CommandService

 echo ""
 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 describe com.daml.ledger.api.v1.CommandSubmissionService

grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 describe com.daml.ledger.api.v1.SubmitRequest

 grpcurl -H "Authorization: Bearer $JWT" -cacert "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" $CURL_CERT_PARAM ledger.$DOMAIN:6865 describe com.daml.ledger.api.v1.Commands
