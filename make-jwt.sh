#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

# https://gist.github.com/indrayam/dd47bf6eef849a57c07016c0036f5207

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then
   echo "Using local signing of JWT"
else
   echo "THIS IS NOT USED FOR AUTH0 AUTHENTICATION"
   exit 1
fi

if [ ! -d certs ] ; then
   mkdir certs
fi

if [ ! -d certs/jwt ] ; then
   mkdir certs/jwt
fi


# source env.sh
ROOTDIR="$(pwd)"
DOMAIN="acme.com"
DOMAIN_NAME="Acme Corp, LLC"
# On MacOS use brew installed openssl 1.1.1
export PATH=/usr/local/opt/openssl/bin:$PATH

ISSUE_DATE=`date "+%s"`
EXPIRY_DATE=$((`date "+%s"` +24*60*60 ))
#LEDGER_ID="46a1600d-bc95-44bd-9269-f6a6912e3351"
APPLICATION_ID="ex-secure-daml-infra"
SIGNING_KEY=certs/signing/jwt-sign.$DOMAIN.key.pem

make_jwt_signing() {
  echo " Generating local signing key JWT"
  openssl genpkey -out $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  openssl req -new -key $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.key.pem \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=jwt-sign.$DOMAIN" \
      -addext "subjectAltName = DNS:client1.$DOMAIN, IP:127.0.0.1" \
      -out $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.csr.pem

  # Sign Client Cert
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions sign_cert -notext -md sha256 \
      -in $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.cert.pem

  # Validate cert is correct
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.cert.pem
}

make_jwks() {
  echo "Creating JKWS for local signer..."
  FINGERPRINT=`openssl x509 -in $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.cert.pem -fingerprint -sha1`
  SIGNING_DER=`openssl x509 -in $ROOTDIR/certs/signing/jwt-sign.$DOMAIN.cert.pem -outform DER | base64 `
  INTERMEDIATE_DER=`openssl x509 -in $ROOTDIR/certs/intermediate/certs/intermediate.cert.pem -outform DER | base64 `
  ROOT_DER=`openssl x509 -in $ROOTDIR/certs/root/certs/ca.cert.pem -outform DERi | base64 `

  which python3
  python3 --version
  python3 make-jwks.py $DOMAIN "$FINGERPRINT" "$SIGNING_DER" "$INTERMEDIATE_DER" "$ROOT_DER"
}

make_jwt() {
  echo "Making JWT Token for $1"

  KEY_ID=`cat "$(pwd)/certs/jwt/jwks.json" | jq .keys[0].kid | tr -d '"'`
  HEADER_TEMPLATE="{\"alg\":\"RS256\",\"typ\":\"JWT\", \"kid\": \"$KEY_ID\" }"
  HEADER=`echo -n $HEADER_TEMPLATE | openssl base64 -e -A | sed s/\+/-/g | sed -E s/=+$//g`

  if [ "" == "$2" ] ; then
     PAYLOAD_TEMPLATE="{\"https://daml.com/ledger-api\": {\"ledgerId\": \"$LEDGER_ID\", \"admin\": $3, \"actAs\": [$4], \"readAs\": [$4]}, \"exp\": $EXPIRY_DATE, \"aud\": \"https://daml.com/ledger-api\", \"azp\": \"$1\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"gty\": \"client-credentials\", \"sub\": \"$1@clients\" }"
  else 
     PAYLOAD_TEMPLATE="{\"https://daml.com/ledger-api\": {\"ledgerId\": \"$LEDGER_ID\", \"applicationId\": \"$2\", \"admin\": $3, \"actAs\": [$4], \"readAs\": [$4]}, \"exp\": $EXPIRY_DATE, \"aud\": \"https://daml.com/ledger-api\", \"azp\": \"$1\", \"iss\": \"local-jwt-provider\", \"iat\": $ISSUE_DATE, \"gty\": \"client-credentials\", \"sub\": \"$1@clients\" }"
  fi

  echo $PAYLOAD_TEMPLATE
  PAYLOAD=`echo -n "$PAYLOAD_TEMPLATE" | openssl base64 -e -A | sed s/\+/-/g | sed -E s/=+$//g`
  DIGEST=`echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign $SIGNING_KEY -binary | openssl base64 -e -A | sed s/\+/-/ | sed -E s/=+$//`

  JWT=$HEADER.$PAYLOAD.$DIGEST
  echo -n $JWT > certs/jwt/$1.token
  #echo "$1 Token: $JWT"
  #echo ""
}

mkdir -p certs/jwt
mkdir -p certs/signing

if [ ! -f certs/signing/jwt-sign.$DOMAIN.cert.pem ] ; then
  make_jwt_signing
  make_jwks
fi

make_jwt "alice" "ex-secure-daml-infra" false "\"Alice\""
make_jwt "bob" "ex-secure-daml-infra" false "\"Bob\""
make_jwt "george" "ex-secure-daml-infra" false "\"George\""
make_jwt "m2m" "ex-secure-daml-infra" true " \"Bob\", \"Alice\", \"edward-digitalasset-com\", \"George\" "
make_jwt "json" "HTTP-JSON-API-Gateway" false ""
make_jwt "navigator" "" true " \"Bob\", \"Alice\", \"edward-digitalasset-com\", \"George\" "

