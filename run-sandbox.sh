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

if [ ! -f daml-on-sql-1.10.0.jar ]; then
   wget https://github.com/digital-asset/daml/releases/download/v1.10.0/daml-on-sql-1.10.0.jar
fi

OCSP_STAPLE="TRUE"
if [ "$OCSP_STAPLE" == "TRUE" ] ; then
   export JDK_JAVA_OPTIONS="-javaagent:$ROOTDIR/jSSLKeyLog.jar=server.log -Djava.security.properties=$ROOTDIR/java.security -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=true -Djava.security.debug='certpath ocsp' -Djavax.net.debug='ssl:handshake,verbose,respmgr'"
   wget https://github.com/jsslkeylog/jsslkeylog/releases/download/v1.3.0/jSSLKeyLog-1.3.zip -O jSSLKeyLog-1.3.zip
   unzip -o jSSLKeyLog-1.3.zip jSSLKeyLog.jar
   JAR="daml-on-sql-binary_deploy.jar"
   if [ ! -f $JAR ] ; then
      echo "WARNING: OCSP depends on a custom build of daml-on-sql to use JDK SSLProvider"
      exit 1
   fi
else
   JAR="daml-on-sql-1.10.0.jar"
fi

echo $JDK_JAVA_OPTIONS

java -jar $JAR \
 ./dist/ex-secure-daml-infra-0.0.1.dar \
 --client-auth $CLIENT_CERT_AUTH_PARAM \
 --sql-backend-jdbcurl "jdbc:postgresql://db.$DOMAIN/ledger?user=ledger&password=LedgerPassword!&ssl=true&sslmode=verify-full&sslrootcert=$ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem&sslcert=$ROOTDIR/certs/client/client1.$DOMAIN.cert.der&sslkey=$ROOTDIR/certs/client/client1.$DOMAIN.key.der" \
 $SIGNER_URL \
 --log-level DEBUG \
 --ledgerid $LEDGER_ID \
 --cacrt "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem" \
 --pem "$(pwd)/certs/server/private/ledger.$DOMAIN.key.pem" \
 --crt "$(pwd)/certs/server/certs/ledger-chain.$DOMAIN.cert.pem" \
 $OCSP_CHECKING
