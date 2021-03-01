[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# TechNote: Certificate Revocation

Digital certificates in the form of server-side TLS certificates and client-side mutual authentication certificates are used 
to authenticate and protect data in transit. Mutual authentication allows both sides to validate who they are 
connecting to and make decisions around whether this is acceptable. 

However digital certificates can be lost, stolen, expired, revoked, and each side may want to perform further validation. Over the 
years, many mechanisms have been developed to allow applications to validate the certificate and these have different tradeoffs.

This TechNote documents the certificate revocation mechanisms, some options to enable debugging of the flows
and some instructions on how to the use to provided test scripts and programs to test out revocation 
options.

## Types of Certificate Revocation Checks

Certificate Revocation mechanisms include:

- **Certificate Revocation Lists (CRL)**
  - A signed list of Certificates that have been revoked by the CA
- **OCSP**
  - Protocol to allow clients of the Certificate Authority to request status of specific certs
- **OCSP Stapling**
  - Enhancement to OCSP to allow the server to "staple" the OCSP response removing need for individual clients to check
- **OCSP Must-Staple**
  - New extension for certificates for indicates to browsers they should expect an OCSP Staple response. This has limited support.
- **Chrome CRLSets / Firefox OneCRL**
  - Browser revocation standard where CRLS for primary public CAs are distributed to end-user browsers

Below are some short descriptons of each mechanism and the drawebacks for each one. See the **References** for
other articles that discuss these topics.

**Certificate Revocation Lists (CRLs)** were the first method for checking certificates. This is a file containing a signed list of 
certificates that have been revoked. Clients would download this list and validate certificates against this list. The main 
challenge with their use is the size of the file can become very large, very quickly especially for busy CAs and systems would need
to download this file frequently if they require quick revocation periods. In 
general CRLS are not used in most systems today.

**OCSP** was the next proposal on how to handle revocation. Instead of download the complete set, systems could
make calls the the OCSP Responder of the CA for specific certificates and obtain a status of the 
certificate. This resolves the size and frequency issues but introduces some new concerns. In particular,
concerns include: availability concerns of the OCSP responder (Apple suffered an outage in 2020 when
their OCSP server went offline temporarily); performance delays (each use of certificate required a call from the client and/or 
server and waiting on the response during connection setup) and privacy concerns (the CA sees 
all clients who are attempting to access any service they provide certificates for).

**OCSP Stapling** attempts to solve the performance and privacy issues of OCSP. The server
makes the OCSP call of behalf of all clients connecting to the service and "staples" the response
in the Server response of the TLS negotiation. In this way, enabled clients receive
a copy of the response with the certificate and can validate without needing to make OCSP calls themselves.
This is still prone to availability concerns although the server can cache the OCSP response for a while. 

The next two mechanisms wre mainly introduced for browsers and are not directly supported by
the Java JDK.

**OCSP Must-Staple**. OCSP has one failing in that many clients will Soft-Fail, i.e. allow connections
to proceed if they do not receive an OCSP response in time. This leads toa false sense of security as
clients will not fail closed. OCSP Must-Staple is a new Certificate extension that the 
CA can set on each certificate requiring clients to receive and validate an 
OCSP response for the certificate. Unfortunately client support for this extension is
not complete.

**Chrome CRLSet / Firefox OneCRL**. These are browser specific solutions to the 
revocation issue. The browser vendors collate a list of CRLs for major Certificate Authority certificates (the CA 
not the end leaf certificates) and distribute as part of their browser package. This resolves the download issue 
but does not support other CAs or end-leaf certificates. It is focused on revoking CAs that
are found to be compromised.

**Other mechanisms**

Another mechanism tat can be used is to issue certificates with short lifetimes. Connections are 
restricted to short periods without incurring the revocation cost / complexity.

# Java, TLS and Certificate Revocation, Debug Options

Before we look at demonstrations of OCSP and OCSP Stapling with Java and Daml, here are some 
techniques to debug the TLS connections and see what is happening on the wire.

## To enable certificate revocation

See Oracle documentation (link in **References**) around these options

```
# Add ocsp.enable=true into security properties. The following overrides
-Djava.security.properties=$ROOTDIR/java.security

# The following enables OCSP
-Dcom.sun.net.ssl.checkRevocation=true 

# Enable CRL checking
-Dcom.sun.security.enableCRLDP=true

# The following additionally enable OCSP Stapling
-Djdk.tls.client.enableStatusRequestExtension=true 
-Djdk.tls.server.enableStatusRequestExtension=true 
```

Implementation Notes:
- Java JDK expects certificates to be in truststore format so TLS Client/Server example imports
into Truststores and Keystores. See ```run-tls-server.sh```

## Java TLS Debug options

Debugging TLS issues can be challenging. The following enables debug logging to the JDK
TLS stack, particularly ```certpath``` (Certificate validation), ```ocsp``` (additional option for OCSP in certpath),
```ssl:handshake``` (TLS process handling) and ```respmgr``` (debug Response Manager which
handles OCSP responses and other items)

```aidl
-Djava.security.debug="certpath ocsp" 
-Djavax.net.debug="ssl:handshake,verbose,respmgr" 
```

Implementation Notes:
- JDK OCSP Checker expects the TLS certificate to contain the full CA trust chain with the
server cert first followed by intermediate and root. Just returning the server certificate without chain
will produce a "OCSP is Disabled" message in debug trace of respmgr. Concatenate the server and CS certs into the
certificate PEM file resolves the issue.   

## Wireshark and traffic captures

To be able to see the traffic flows between client and server, it can help to use Wireshark. However TLS is encrypted by default
and traffic data is hidden. This can be resolved by enabling TLS Session key logging. See **References** for links
to details articles and setup. 

For the JDK, you can use the jSSLKeyLog agent to capture the TLS session key to a file and then configure Wireshark to
read. Wireshark is then able to decrypt the traffic, which is required to see some packate details (for example, the
OCSP Staple response details)
```aidl
-javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log 
```

Similarly, it is also possible to trace the GRPC/Protobuf traffic by configuring the 
Protobuf add-in Wireshark to use the Daml protobuf files. You may need to download Daml
repo and Google base grpc protobuf files for this to work successfully.

# Certificate Revocation Demonstration

## TCP Socket, TLS OCSP and OCSP Stapling

This example tests out Java JSSE implementation of OCSP and OCSP Stapling with or without client authentication. 
The server allows the client to request and download the contents of a file in the server directory. The code 
is available in:

```aidl
- sockets
   - client - two clients (switch in the bash script) to connect and optionally authenticate to server
   - server - server listener that accepts connects and requests for a file contents
```

This example includes:
- create a sample PKI infrastructure
- Run OCSP Responders for Root and Intermediate CAs
- Run a TLS Server
- Run a Client application to call server

Sample Notes:
- You need to download the JSSLKeyLog jar file if you wish to capture the TLS session keys for Wireshark analysis (see References section below)
- The ```ocsp.enable=true``` parameter needs to be set in java.security properties file or in code. It is not an environment or system variable
- Java JSSE Requires JKS format certification store files so make-certs imports the certificates into trust and key stores. There are simpler ways but this aligns with the overall sample PKI hierarchy.

```aidl
# Construct example two tier PKI
./make-certs.sh

# Create Root OCSP signing cert and run OCSP Responder
./run-root-ocsp.sh

# Construct Intermediate CA OCSP Certification and run responder 
./run-ocsp.sh

# Run a TLS Server
# Optionally you can enable / disable TLS Mutual Authentication
./run-tls-server.sh

# Run a TLS Client
# Note you can switch between standard TLS and Mutual TLS clients
# Client should show contents of the test.txt file in the server directory 
./run-tls-client.sh
```

What do the Java parameters do?
```aidl
# Enable TLS session key capture for Wireshark analysis
-javaagent:$ROOTDIR/jSSLKeyLog.jar=jssl-key.log

# Enable Java JSSE certpath and ocsp debug logging
-Djava.security.debug="certpath ocsp" 
# Enable Java JSSE TLS handshake debug logging
-Djavax.net.debug="ssl:handshake" 

# Enable OCSP Checking in Java JSSE - requires java security properties override or in code
-Djava.security.properties=$ROOTDIR/java.security

# Enable Revocation Checking
-Dcom.sun.net.ssl.checkRevocation=true
# Enable client side OCSP extensions 
-Djdk.tls.client.enableStatusRequestExtension=true
# Enable server side OCSP extensions 
-Djdk.tls.server.enableStatusRequestExtension=true

# Override Java JSSE default trust keystore  
-Djavax.net.ssl.trustStore=$ROOTDIR/certs/intermediate/certs/local-truststore.jks
# Password for trust keystore (and yes you should change it!) 
-Djavax.net.ssl.trustStorePassword=changeit
```

## Daml Server-Side OCSP Certificate Revocation Checking

The Daml Drivers allow OCSP (but currently not OCSP Stapling) to be enabled. This is enabled with the flag:

```aidl
--cert-revocation-checking true
```

NOTE: See next section for discussion on OCSP Stapling requirements 

Sequence to setup and run environment
```aidl
# Ensure the following values are set to correct value in env.sh
CLIENT_CERT_AUTH=TRUE
LOCAL_JWT_SIGNING=TRUE
DOCKER_COMPOSE=FALSE
OCSP_CHECKING="--cert-revocation-checking true"

./clean.sh
./build.sh
./run-docker.sh           # runs make-certs.sh and sets up Docker env
./run-root-ocsp.sh
./run-ocsp.sh
./run-sandbox.sh
./test-ocsp.sh
```

The final step demonstrates:
- create a test cert
- accessing the ledger and retrieving the Ledger API version
- revoking the cert
- access ledger again and see access failure from revoked cert

## Daml Server-Side OCSP Stapling

The default TLS Provider used by Daml is BoringSSL. This is a simplified implementation that
reduces the TLS code base and removes a variety of features, particularly those that are not
used frequently. This includes OCSP Stapling. It is possible to reconfigure Daml to use the installed JDK in preference to 
Boring SSL but this currently requires a custom build of Daml API Server. 

Two files need to be updated in the following directory in the Daml source code tree.

```aidl
ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/
```

Diff set for example code is:

```aidl
diff --git a/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/OcspProperties.scala b/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/OcspProperties.scala
index bdbf2e4947..a227502522 100644
--- a/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/OcspProperties.scala
+++ b/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/OcspProperties.scala
@@ -11,11 +11,15 @@ object OcspProperties {

   val CheckRevocationPropertySun: String = "com.sun.net.ssl.checkRevocation"
   val CheckRevocationPropertyIbm: String = "com.ibm.jsse2.checkRevocation"
+  val ClientStatusRequestExtension: String = "jdk.tls.client.enableStatusRequestExtension"
+  val ServerStatusRequestExtension: String = "jdk.tls.server.enableStatusRequestExtension"
   val EnableOcspProperty: String = "ocsp.enable"

   def enableOcsp(): Unit = {
     System.setProperty(CheckRevocationPropertySun, True)
     System.setProperty(CheckRevocationPropertyIbm, True)
+    System.setProperty(ClientStatusRequestExtension, True)
+    System.setProperty(ServerStatusRequestExtension, True)
     java.security.Security.setProperty(EnableOcspProperty, True)
   }

diff --git a/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/TlsConfiguration.scala b/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/TlsConfiguration.scala
index c61c21b1ed..1ddbb9a666 100644
--- a/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/TlsConfiguration.scala
+++ b/ledger/ledger-api-common/src/main/scala/com/digitalasset/ledger/api/tls/TlsConfiguration.scala
@@ -6,7 +6,7 @@ package com.daml.ledger.api.tls
 import java.io.File

 import io.grpc.netty.GrpcSslContexts
-import io.netty.handler.ssl.{ClientAuth, SslContext}
+import io.netty.handler.ssl.{ClientAuth, SslContext, SslProvider, SslContextBuilder}

 import scala.jdk.CollectionConverters._

@@ -54,10 +54,11 @@ final case class TlsConfiguration(
     if (enabled)
       Some(
         GrpcSslContexts
-          .forServer(
-            keyCertChainFileOrFail,
-            keyFileOrFail,
-          )
+          //.forServer(
+          //  keyCertChainFileOrFail,
+          //  keyFileOrFail,
+          //)
+          .configure(SslContextBuilder.forServer(keyCertChainFileOrFail, keyFileOrFail), SslProvider.JDK)
           .trustManager(trustCertCollectionFile.orNull)
           .clientAuth(clientAuth)
           .protocols(if (protocols.nonEmpty) protocols.asJava else null)
```

after building and creating the custom jar file

```aidl
bazel build //ledger/daml-on-sql:daml-on-sql-binary_deploy.jar
```

Copy this to main directory of project. Update the run-sandbox.sh to enable full Stapling Support.

The same set of command to the above OCSP test can be used to see OCSP Stapling.


# References

## JDK
- [JDK PKI Programmers Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/certpath/CertPathProgGuide.html)
- [Oracle - Client-Driven OCSP and OCSP Stapling](https://docs.oracle.com/javase/8/docs/technotes/guides/security/jsse/ocsp.html)

## Discussions on revocation and current state
- [Revocation is broken](https://scotthelme.co.uk/revocation-is-broken/)
- [Why Do Certificate Revocation Checking Mechanisms Never Work?](https://pfeifferszilard.hu/2020/09/09/why-do-certificate-revocation-checking-mechanisms-never-work.html)
- [The Problem with OCSP Stapling and Must Staple and why Certificate Revocation is still broken](https://blog.hboeck.de/archives/886-The-Problem-with-OCSP-Stapling-and-Must-Staple-and-why-Certificate-Revocation-is-still-broken.html)
- [Fixing Certificate Revocation](https://tersesystems.com/blog/2014/03/22/fixing-certificate-revocation/)
- [SSL certificate revocation and how it is broken in practice](https://medium.com/@alexeysamoshkin/how-ssl-certificate-revocation-is-broken-in-practice-af3b63b9cb3)
- [The current state of certificate revocation (CRLs, OCSP and OCSP Stapling)](https://www.maikel.pro/blog/current-state-certificate-revocation-crls-ocsp/)

## OCSP Stapling, Must-Staple, CRLSet
- [Everything You Need to Know About OCSP, OCSP Stapling & OCSP Must-Staple](https://www.thesslstore.com/blog/ocsp-ocsp-stapling-ocsp-must-staple/)
- [On validation of Web X509 Certificates by TLS inception products](https://s3.amazonaws.com/ieeecs.cdn.csdl.content/trans/tq/5555/01/09110796.pdf?AWSAccessKeyId=ASIA2Z6GPE73HGDVU2RA&Expires=1614817088&Signature=H6J7bioUhIo%2FmfiWh5otfhVvoiI%3D&x-amz-security-token=IQoJb3JpZ2luX2VjELH%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJHMEUCIGfU2itZ%2B3ky3kr9vlXTwp2KKfVKmV5yPtGqmA8aC3R5AiEAkKWSmqIUTccmeL2DHElc86Ri2IOqN7CgqqhYDrNCD6Yq4AEIyf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgw3NDI5MDg3MDA2NjIiDKb%2FrbzvOxcuCWxGQyq0AZ5sHVzDbxBoPOBrsDi7hs3fpiwnqKtiMJtuDQdr5kYwrouuEWIoZJjz%2FTwzuH9BjiVdOYXfT0rFhC6xk0y6CSH4sGakrSx7optIbrIKlum4ZC4%2BtEmva0bV8FI4BBVVsLJqSNd6rd5POPRvfLnr6nDAzipKjiPhH2%2F7VbTvhux%2FyEjEuVNxLORSV4alTsgWhTSoQFxJPEYuqlTrp%2BFxyjbN%2FyTkgYj0RtTw9SczxU5HZexh6zC8yoCCBjrgAfPVzMBs8%2BIS7eujPDfIeZHFt2UFzvcSUkUqNeC94bj1zJWz%2BCai0FvMGT7G1w5hPg7yo1kp2bkuZFx93gPaRPlCCdl4TivjuEh33dRkTcY3cb1ZJ%2FtT7Nz4bIFq0YiSg%2BkeY67M%2FwWvgJv95%2BqDI5lQQiGltd6OUT%2FJQPOWcBY3KDo0T1oHpcOdELE%2F03PiEutEK9Lto464t9s8uwso8Bs6YpWXBTENWJmnfFKE24vQU8dlBj1KA368w3%2Bjck%2FwB0BemUUxOv%2BOshh5myr%2BJ7m7Mz0EGexgsOUdmJO1vXlN)
- [Venafi - OCSP Must-Staple: Revocation That Works](https://www.venafi.com/blog/ocsp-must-staple)  
- [Is the web ready for OCSP Must-Staple?](https://blog.apnic.net/2019/01/15/is-the-web-ready-for-ocsp-must-staple/)

## Wireshark Tracing
- [Wireshark - TLS](https://wiki.wireshark.org/TLS)
- [Analyzing gRPC messages using Wireshark](https://grpc.io/blog/wireshark/)
- [Decrypting SSL traffic on Wireshark using jSSLKeyLog](https://community.microfocus.com/t5/ZENworks-Tips-Information/Decrypting-SSL-traffic-on-Wireshark-using-jSSLKeyLog/ta-p/2811103)


Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0





