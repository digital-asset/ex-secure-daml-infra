#!/bin/bash

source env.sh

cd sockets/server

java -javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log -Djava.security.debug="certpath ocsp" -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=true -Djavax.net.debug="ssl:handshake" -Djava.security.properties=$ROOTDIR/java.security -Djavax.net.ssl.trustStore=$ROOTDIR/certs/intermediate/certs/local-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit ClassFileServer 6666 $ROOTDIR/sockets/server $ROOTDIR/certs/server/certs/ledger.$DOMAIN.jks true
