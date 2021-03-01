#!/bin/bash

source env.sh

cd sockets/client

if [ ! -f SSLSocketClient.class ] ; then
  javac *.java
fi

java -javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log  -Djava.security.debug="certpath ocsp" -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=true -Djavax.net.debug="ssl:handshake" -Djava.security.properties=$ROOTDIR/java.security -Djavax.net.ssl.trustStore=$ROOTDIR/certs/intermediate/certs/local-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit SSLSocketClientWithClientAuth localhost 6866 $ROOTDIR/certs/client/client1.$DOMAIN.jks /test.txt

#java -javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log  -Djava.security.debug="certpath ocsp" -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=false -Djavax.net.debug="ssl:handshake" -Djava.security.properties=$ROOTDIR/java.security -Djavax.net.ssl.trustStore=$ROOTDIR/certs/intermediate/certs/local-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit SSLSocketClient localhost 6866 /test.txt
