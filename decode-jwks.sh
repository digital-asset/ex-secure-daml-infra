#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

function decode {
  _l=$((${#1} % 4))
  if [ $_l -eq 2 ]; then _s="$1"'=='
  elif [ $_l -eq 3 ]; then _s="$1"'='
  else _s="$1" ; fi
  DECODED_VALUE=`echo "$_s" | tr '_-' '/+' | base64 -d`
}

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then
  JWKS=`cat certs/jwt/jwks.json`
else
  JWKS=`curl -s https://digitalasset-dev.auth0.com/.well-known/jwks.json`
fi

echo $JWKS | jq .

ALG=`echo $JWKS | jq .keys[0].alg`
N=`echo $JWKS | jq .keys[0].n | tr -d '"' `

X5C=`echo $JWKS | jq .keys[0].x5c[0] | tr -d '"' `
#echo $X5C

/usr/local/opt/openssl/bin/openssl enc -base64 -d -A <<< "$X5C" > x5c.der
/usr/local/opt/openssl/bin/openssl x509 -inform DER -in x5c.der -text -fingerprint -sha1
rm x5c.der

X5T=`echo -n $JWKS | jq .keys[0].x5t | tr -d '"' `
#echo "$X5T"
#FINGERPRINT=`echo -n $X5T | base64 -d`
decode "$X5T"
FINGERPRINT=$DECODED_VALUE
echo "========================"
echo "Fingerprint check"
printf '%s' "$FINGERPRINT" | awk '{ print toupper($0) }'
echo ""

