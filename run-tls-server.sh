#!/bin/bash

source env.sh

create_jks_truststore() {
  keytool -import -alias root -file "$ROOTDIR/certs/root/certs/ca.cert.pem" -keystore "$ROOTDIR/certs/intermediate/certs/local-truststore.jks" -storepass changeit -noprompt
  keytool -import -alias intermediate -file "$ROOTDIR/certs/intermediate/certs/intermediate.cert.pem" -keystore "$ROOTDIR/certs/intermediate/certs/local-truststore.jks" -storepass changeit -noprompt
  keytool -list -keystore "$ROOTDIR/certs/intermediate/certs/local-truststore.jks" -storepass changeit
}

create_jks_client_keystore() {
  cd $ROOTDIR
  cat "$ROOTDIR/certs/client/client1.acme.com.cert.pem" "$ROOTDIR/certs/intermediate/certs/intermediate.cert.pem" "$ROOTDIR/certs/root/certs/ca.cert.pem" > import.pem
  echo "changeit" | openssl pkcs12 -export -password stdin -in import.pem -inkey "$ROOTDIR/certs/client/client1.acme.com.key.pem" -name client > client.p12
  echo "changeit" | keytool -importkeystore -srckeypass changeit -destkeypass changeit -noprompt -srckeystore client.p12 -destkeystore "$ROOTDIR/certs/client/client1.acme.com.jks" -srcstoretype pkcs12 -alias client -storepass changeit
  keytool -list -keystore "$ROOTDIR/certs/client/client1.acme.com.jks" -storepass changeit
}

create_jks_server_keystore() {
  cd $ROOTDIR
  cat "$ROOTDIR/certs/server/certs/ledger.acme.com.cert.pem" "$ROOTDIR/certs/intermediate/certs/intermediate.cert.pem" "$ROOTDIR/certs/root/certs/ca.cert.pem" > import.pem
  echo "changeit" | openssl pkcs12 -export -password stdin -in import.pem -inkey "$ROOTDIR/certs/server/private/ledger.acme.com.key.pem" -name server > server.p12
  echo "changeit" | keytool -importkeystore -srckeypass changeit -destkeypass changeit -noprompt -srckeystore server.p12 -destkeystore "$ROOTDIR/certs/server/certs/ledger.acme.com.jks" -srcstoretype pkcs12 -alias server -storepass changeit
  keytool -list -keystore "$ROOTDIR/certs/server/certs/ledger.acme.com.jks" -storepass changeit
}

create_jks_truststore
create_jks_client_keystore
create_jks_server_keystore

cd sockets/server

if [ ! -f ClassFileServer.class ] ; then
  javac *.java
fi

java -javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log -Djava.security.debug="certpath ocsp" -Djavax.net.debug="ssl:handshake,verbose,respmgr" -Dcom.sun.net.ssl.checkRevocation=true -Djdk.tls.client.enableStatusRequestExtension=true -Djdk.tls.server.enableStatusRequestExtension=true -Djava.security.properties=$ROOTDIR/java.security -Djavax.net.ssl.trustStore=$ROOTDIR/certs/intermediate/certs/local-truststore.jks -Djavax.net.ssl.trustStorePassword=changeit ClassFileServer 6866 $ROOTDIR/sockets/server $ROOTDIR/certs/server/certs/ledger.$DOMAIN.jks true
