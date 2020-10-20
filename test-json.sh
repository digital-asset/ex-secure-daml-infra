#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Documentation on JSON API
# https://docs.daml.com/json-api/index.html

source env.sh

CLIENT_CERT_PARAM=""
CURL_CERT_PARAM=""
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CURL_CERT_PARAM="--key $(pwd)/certs/client/client1.$DOMAIN.key.pem --cert $(pwd)/certs/client/client1.$DOMAIN.cert.pem "
fi

if [ ! -f "certs/jwt/m2m.token" ] ; then
  echo "WARNING: Need to retrieve M2M authentication token first!"
  ./get-m2m-token.sh
fi

AUTH_TOKEN=`cat "certs/jwt/m2m.token"`

echo ""
echo "Getting all current parties"
RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://web.$DOMAIN:8000/v1/parties`
echo $RESULT | jq .

echo ""
echo "Getting all current DAR packages"
RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://web.$DOMAIN:8000/v1/packages`
echo $RESULT | jq .

AUTH_TOKEN=
RESULT=


# Set the following to the user token
# UPDATE THE FOLLOWING
#
AUTH_TOKEN_NAME="george.token"
#PARTY_ID="<put PartyID-here>"
PARTY_ID="George"
NEW_PARTY_ID="Bob"

if [ ! -f "certs/jwt/$AUTH_TOKEN_NAME" ] ; then
  echo "ERROR: Please set user authentication up first!"
  exit 1
fi

AUTH_TOKEN=`cat "certs/jwt/$AUTH_TOKEN_NAME"`

# Tests
# Get all contracts for Party
# Create a new Asset for Party
# Move Asset to new owner

echo ""
echo "Getting all current contracts"

RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM \
  -X GET -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  https://web.$DOMAIN:8000/v1/query`
echo $RESULT | jq .

# Create a new contract via JSON API
echo ""
echo "Creating new contract"
RANDOM_STRING=`openssl rand -hex 16`
RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $AUTH_TOKEN" -d "{ \"templateId\": \"Main:Asset\", \"payload\": {\"owner\": \"$PARTY_ID\",\"name\": \"TV-$RANDOM_STRING\", \"issuer\": \"$PARTY_ID\"}}" https://web.$DOMAIN:8000/v1/create`

echo $RESULT | jq .

STATUS=`echo $RESULT | jq .status `
if [ "$STATUS" != "200" ] ; then
  echo "ERROR: Failure executing command!"
  exit
fi
echo "Status: $STATUS"

CONTRACT_ID=`echo $RESULT | jq .result.contractId  | tr -d '"'`
echo "Contract ID: $CONTRACT_ID"

# Exercise choice on contract created above
echo ""
echo "Moving asset"
RESULT=`curl -s --cacert ./certs/intermediate/certs/ca-chain.cert.pem $CURL_CERT_PARAM -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $AUTH_TOKEN" -d "{ \"templateId\": \"Main:Asset\", \"contractId\": \"$CONTRACT_ID\", \"user\": \"PARTY_ID\", \"choice\": \"Give\", \"argument\": { \"newOwner\": \"$NEW_PARTY_ID\" }}" https://web.$DOMAIN:8000/v1/exercise`

echo $RESULT | jq .

STATUS=`echo $RESULT | jq .status `
if [ "$STATUS" != "200" ] ; then
  echo "ERROR: Failure executing command!"
  exit
fi
echo "Status: $STATUS"

CONTRACT_ID=`echo $RESULT | jq .result.exerciseResult `
echo "Contract ID: $CONTRACT_ID"

