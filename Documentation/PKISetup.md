[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Public Key Infrastructure

To demonstrate a representative PKI, we are going to set up a two tier CA with a Root CA and an 
Intermediate CA. There are other potential configurations that split out CAs for client certificiates, 
server certificates and code signing but this will depend on your requirements.

This reference sample uses local files for all private key material. Please keep in mind that this material is vital to the security of the system and 
should be secured appropriately. The steps to achieve this in production are left to the reader. We also do not demonstrate HSM integration for private key generation or storage.

# Implementation

These setup steps are implemented in the ```make-certs.sh``` script. This creates the full hierarchy in a directory tree under the ```certs``` sub-directory.

- project-root
  - certs
    - root
      - certs
      - private
      - csr
    - intermediate
      - ..as above..
    - server
      - ..as above..
    - client
    - jwt

# Root CA Setup

This step creates the Root CA - the basis of trust for all certificates issued by this PKI. 
The root key is generated and then self-signed. NOTE: This Root is not trusted by default by your 
machine so you would need to import into your machine trust store (KeyChain) for 
browsers to not warn about these certificates. Trusted Public PKI CA certificates on the Internet are added to 
the trust stores of the OS and Browsers by default.

The Root CA is configured with a long lifetime as this is usually kept offline and the private keys stored 
very securely. 

```$xslt
  # Generate the root CA private key and ensure it is read-only
  openssl genrsa -out $ROOTDIR/certs/root/private/ca.key.pem 4096
  chmod 400 $ROOTDIR/certs/root/private/ca.key.pem

  # Create Root Certificate (self-signed)
  openssl req -config root/openssl.cnf \
      -key root/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=root-ca.$DOMAIN" \
      -out /certs/ca.cert.pem

  # Dump out cert details
  openssl x509 -noout -text -in certs/root/certs/ca.cert.pem
```

# Intermediate CA

The Intermediate CA follows a similar process. However we generates a CSR request and get the Root CA to sign this. This
shows that the Intermediate CA is trusted by the Root and forms the "Chain of Trust"

```$xslt
  # Generate Intermediate private key
  openssl genrsa \
      -out intermediate/private/intermediate.key.pem 4096
  chmod 400 intermediate/private/intermediate.key.pem

  # Create Intermediate CSR request
  openssl req -config intermediate/openssl.cnf -new -sha256 \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=intermediate-ca.$DOMAIN" \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem

  # Sign Intermediate Certificate by Root CA
  openssl ca -batch -config root/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

  chmod 444 intermediate/certs/intermediate.cert.pem

  # Verify Certificate
  openssl x509 -noout -text -in intermediate/certs/intermediate.cert.pem

  # Create certificate chain by concatenating the Root and Intermediate CA certificates
  cat intermediate/certs/intermediate.cert.pem \
      root/certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
  chmod 444 intermediate/certs/ca-chain.cert.pem
  cp root/certs/ca.cert.pem intermediate/certs/root-ca.cert.pem
```
# Server Certificates

We create our first TLS certificate for a device, in this case for server.acme.com.   

For TLS certificates, we add both a Subject and Subject Alternate Name (SAN - often DNS name or IP)and set certificate attributes retricting the certificates use. 
Most modern browsers expect this to be set to fully trust a certificate. These are signed by the Intermediate CA. 

One important difference to note is we use the ```openssl getpkey``` instead of ```openssl getrsa``` command to create a PKCS8 format private key. The latter produces 
a PKCS1 format file. The difference between PKCS1 and PKCS8 is that PKCS8 includes a header that describes the format of the enclosed certificate 
in addition to the private key. The libraries used for Ledger Server and its tools expect to get a PKCS8 format file.

We create additional certificates in the provided scripts for the database server.

```$xslt
  # Need to create key in PKCS8 format not native RSA
  openssl genpkey -out server/private/server.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 server/private/server.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=server.$DOMAIN" \
      -addext "subjectAltName = DNS:server.$DOMAIN" \
      -key server/private/server.$DOMAIN.key.pem \
      -new -sha256 -out server/csr/server.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config intermediate/openssl.cnf \
      -extensions server_cert -days 365 -notext -md sha256 \
      -in server/csr/server.$DOMAIN.csr.pem \
      -out server/certs/server.$DOMAIN.cert.pem
  chmod 444 server/certs/server.$DOMAIN.cert.pem

  # Display Certificate contents
  openssl x509 -noout -text \
      -in server/certs/server.$DOMAIN.cert.pem

  # Validate chain of trust - note use of ca-chain containg Root and Intermediate
  openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
      server/certs/server.$DOMAIN.cert.pem
```

# Client Certificates

Client Certificates are used in Mutual TLS Authentication. Server Certificates only tell the 
client application about the server but the server has no knowledge (unless provided within application 
protocols) about the client. Mutual Authentication allows the server to confirm and trust the 
client connecting to the service.

```$xslt
  openssl genpkey -out client/client1.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  openssl req -new -key client/client1.$DOMAIN.key.pem \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=client1" \
      -addext "subjectAltName = DNS:client1.$DOMAIN, IP:127.0.0.1" \
      -out client/client1.$DOMAIN.csr.pem

  # Sign Client Cert
  openssl ca -batch -config intermediate/openssl.cnf \
      -extensions usr_cert -notext -md sha256 \
      -in client/client1.$DOMAIN.csr.pem \
      -out client/client1.$DOMAIN.cert.pem

  # Validate cert is correct
  openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
      client/client1.$DOMAIN.cert.pem
```

# Areas you can do further work on

In this tutorial we will not be covering
- Certificate Revocation List (CRLs)
- OCSP Online Checks

though many of these features are detailed in the provided scripts (```test-ocsp.sh```).

# Next Step

[Auth0 Setup](./Auth0Setup.md)

Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0
