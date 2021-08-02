#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

source env.sh

echo $ROOTDIR
echo $PWD

docker start daml-postgres
docker start daml-nginx
docker start daml-envoyproxy

CLIENT_CERT_PARAM="none"
if [ "$CLIENT_CERT_AUTH" == "TRUE" ] ; then
  echo "Enabling Client Certificate Auth"
  CLIENT_CERT_AUTH_PARAM="require"
fi

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then
   echo "Using local signing of JWT"
   SIGNER_URL="--auth-jwt-rs256-jwks=file://$(pwd)/certs/jwt/jwks.json"
else
   SIGNER_URL="--auth-jwt-rs256-jwks=https://$AUTH0_DOMAIN.auth0.com/.well-known/jwks.json"
fi

# Wait for postgres and nginx to come up
sleep 5

# --pem server.pem --crt server.crt
# --client-auth none|optional|require
# --auth-jwt-rs256-crt=<filename>
# --auth-jwt-es256-crt=<filename>
# --auth-jwt-es512-crt=<filename>
# --auth-jwt-rs256-jwks=<url>
# --auth-jwt-hs256-unsafe=<secret>

if [ ! -f daml-on-sql-1.15.0.jar ]; then
   wget https://github.com/digital-asset/daml/releases/download/v1.15.0/daml-on-sql-1.15.0.jar
fi

if [ "$OCSP_CHECKING" != "" ]; then
  JAVA_OCSP=(-javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log -Djava.security.debug='certpath ocsp' -Djavax.net.debug='ssl:handshake' -Djava.security.properties=$ROOTDIR/java.security -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=true -Djavax.net.ssl.trustStore=$ROOTDIR/certs/intermediate/certs/local-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit)
else
  JAVA_OCSP=()
fi

java \
 "${JAVA_OCSP[@]}" \
 -jar daml-on-sql-1.15.0.jar \
 ./dist/ex-secure-daml-infra-0.0.1.dar \
 --client-auth $CLIENT_CERT_AUTH_PARAM \
 --sql-backend-jdbcurl "jdbc:postgresql://db.$DOMAIN/ledger?user=ledger&password=LedgerPassword!&ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/client/client1.$DOMAIN.cert.der&sslkey=$ROOTDIR/certs/client/client1.$DOMAIN.key.der" \
 $SIGNER_URL \
 --log-level INFO \
 --ledgerid $LEDGER_ID \
 --cacrt "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" \
 --pem "$(pwd)/certs/server/private/ledger.$DOMAIN.key.pem" \
 --crt "$(pwd)/certs/server/certs/ledger-chain.$DOMAIN.cert.pem" \
 $OCSP_CHECKING
