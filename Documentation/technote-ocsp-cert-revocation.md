[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# TechNote: Certificate Revocation

As described elsewhere in this reference sample, digital certificates in the form of Server TLS certificates and client side mutual authentication
certificates are used to authentication and protect data in transit. Mutual authentication allows both sides to validate who they are connecting to
and make decisions around whether this is valid. However digital certificates can be stolen, one side of the communication may no longer be
authorised, etc and each side may want to perform validation about whether the certificate continues to be valid. Over the years, many mechanisms have 
been develeoped to alow applications to validate the certificate and these have different tradeoffs. 

## Types of Certificate Revocation Checks

Certificate Revocation mechanisms include:

- Certificate Revocation Lists (CRL)
  - List of Certificates that have been revoked by the CA
- OCSP
  - Protocol to allow clients of the Certificate Authority to request status of specific certs
- OCSP Stapling
  - Enhancement to OCSP to allow the server to "staple" the OCSP response removing need for individual clients to check
- OCSP Must-Staple
  - New extension for certificates for indicates to browsers they should expect an OCSP Staple response
- CRLSets
  - Browser revocation standard where CRLS for primary public CAs are distributed to end-user browsers

## Discussion on Revocation methods and consequences

- Short Certificate lifetime expiry

# Certificate Revocation Demonstration

## TCP Socket TLS OCSP and OCSP Stapling

This example tests out Java JSSE implementation of OCSP and OCSP Stapling with ot without client authentication. 
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
- The ```ocsp.eable=true``` parameter needs to be set in java.security properties file or in code. It is not an environment or system variable
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

NOTE: The Java parameters mentioned in the section above do not work by default with Scala and Akka framework. 

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

# References

- [Oracle - Client-Driven OCSP and OCSP Stapling](https://docs.oracle.com/javase/8/docs/technotes/guides/security/jsse/ocsp.html)

- [Revocation is broken](https://scotthelme.co.uk/revocation-is-broken/)
- [Why Do Certificate Revocation Checking Mechanisms Never Work?](https://pfeifferszilard.hu/2020/09/09/why-do-certificate-revocation-checking-mechanisms-never-work.html))
- [The Problem with OCSP Stapling and Must Staple and why Certificate Revocation is still broken](https://blog.hboeck.de/archives/886-The-Problem-with-OCSP-Stapling-and-Must-Staple-and-why-Certificate-Revocation-is-still-broken.html)
- [Fixing Certificate Revocation](https://tersesystems.com/blog/2014/03/22/fixing-certificate-revocation/)
- [SSL certificate revocation and how it is broken in practice](https://medium.com/@alexeysamoshkin/how-ssl-certificate-revocation-is-broken-in-practice-af3b63b9cb3)
- [The current state of certificate revocation (CRLs, OCSP and OCSP Stapling)](https://www.maikel.pro/blog/current-state-certificate-revocation-crls-ocsp/)


- [Everything You Need to Know About OCSP, OCSP Stapling & OCSP Must-Staple](https://www.thesslstore.com/blog/ocsp-ocsp-stapling-ocsp-must-staple/)
- [On validation of Web X509 Certificates by TLS inception products](https://s3.amazonaws.com/ieeecs.cdn.csdl.content/trans/tq/5555/01/09110796.pdf?AWSAccessKeyId=ASIA2Z6GPE73HGDVU2RA&Expires=1614817088&Signature=H6J7bioUhIo%2FmfiWh5otfhVvoiI%3D&x-amz-security-token=IQoJb3JpZ2luX2VjELH%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJHMEUCIGfU2itZ%2B3ky3kr9vlXTwp2KKfVKmV5yPtGqmA8aC3R5AiEAkKWSmqIUTccmeL2DHElc86Ri2IOqN7CgqqhYDrNCD6Yq4AEIyf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgw3NDI5MDg3MDA2NjIiDKb%2FrbzvOxcuCWxGQyq0AZ5sHVzDbxBoPOBrsDi7hs3fpiwnqKtiMJtuDQdr5kYwrouuEWIoZJjz%2FTwzuH9BjiVdOYXfT0rFhC6xk0y6CSH4sGakrSx7optIbrIKlum4ZC4%2BtEmva0bV8FI4BBVVsLJqSNd6rd5POPRvfLnr6nDAzipKjiPhH2%2F7VbTvhux%2FyEjEuVNxLORSV4alTsgWhTSoQFxJPEYuqlTrp%2BFxyjbN%2FyTkgYj0RtTw9SczxU5HZexh6zC8yoCCBjrgAfPVzMBs8%2BIS7eujPDfIeZHFt2UFzvcSUkUqNeC94bj1zJWz%2BCai0FvMGT7G1w5hPg7yo1kp2bkuZFx93gPaRPlCCdl4TivjuEh33dRkTcY3cb1ZJ%2FtT7Nz4bIFq0YiSg%2BkeY67M%2FwWvgJv95%2BqDI5lQQiGltd6OUT%2FJQPOWcBY3KDo0T1oHpcOdELE%2F03PiEutEK9Lto464t9s8uwso8Bs6YpWXBTENWJmnfFKE24vQU8dlBj1KA368w3%2Bjck%2FwB0BemUUxOv%2BOshh5myr%2BJ7m7Mz0EGexgsOUdmJO1vXlN)
- [Venafi - OCSP Must-Staple: Revocation That Works](https://www.venafi.com/blog/ocsp-must-staple)  
- [Is the web ready for OCSP Must-Staple?](https://blog.apnic.net/2019/01/15/is-the-web-ready-for-ocsp-must-staple/)
  

- [Wireshark - TLS](https://wiki.wireshark.org/TLS)
- [Decrypting SSL traffic on Wireshark using jSSLKeyLog](https://community.microfocus.com/t5/ZENworks-Tips-Information/Decrypting-SSL-traffic-on-Wireshark-using-jSSLKeyLog/ta-p/2811103)


Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0





