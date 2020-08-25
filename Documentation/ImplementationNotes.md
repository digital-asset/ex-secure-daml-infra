[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Implementation Notes

## Debugging your setup

Security often requires all the stars to align correctly and is often challenging to debug. Some options used during the 
creation of this reference app include:

- Use of OpenSSL s_client command to prove TLS enabled and returning correct settings
- Use of curl and grpcurl to validate APIs and access
- Use ```docker logs --follow <container> ``` to get logs from services  

## Security

- We have not touched on other important security considerations that you should review before running anything in production. These scripts are not intended 
for production use.
- HTTP JSON API requires a front-end proxy to enforce TLS connection. Network segmentation or firewalling should be implemented to 
ensure that applications cannot bypass this proxy. Proxy also needs to send X-Forwarded-For header.

## PKI

- PKCS8 format certificates (start BEGIN PRIVATE KEY) are required by DAML Services. Many tutorials only produce PKCS1 format files (starts BEGIN RSA PRIVATE KEY). PKCS8 include metadata 
about certificate type. It is possible to convert between formats.
- Make sure that --cacrt is set on Ledger Server if client certificates are failing to work. This is by design (client certs are not trusted) but is 
currently difficult to debug (internal feature request). Note the Certificate chain of public keys is placed in ```certs/intermediate/certs/ca-chain.cert.pem``` 
- Implemented specific extensions for client, server, code signing certs in Intermediate openssl.cnf file. Set Subject Alternate Names (SAN) on 
certificates and appropriate certificate extensions. 

## JWT Authentication

- HTTP JSON API requires a public (i.e. non-admin and no rights to any Party) valid token to pull Package information from
the Ledger Server. It will include provide tokens with JSON requests so that are authenticated the same as the caller.
- Use the token decode scripts provided to check the format of the custom claims. PERMISSION_DENIED is often due to incorrect details in the claim.
- Development environments can use ```HS256``` JWT signing but this is inherently insecure (shared key / passphrase)

## CI/CD Automation

Automated execution has been implemented in CircleCI. This performs the following:
  - checkout out latest commit
  - build files
  - copies files to a name volume
  - initializes a Docker Compose environment running all components
  - run tests on the testnode against the other services
  - captures and stores the output

See ```.circleci/config.yml``` for details of the steps.

Main pain points is that you cannot mount directly from build environment to Docker containers and this
step of copying required files. It was also necessary to repermission the files so each service had access as their
respective account ID in each container. PostgresQL for example performs checks on file ownership and permissions before
starting and will fail if these are wrong.

## Miscellaneous

- Base64 vs Base64URL - Base64 encoding is not clean for use in URLs. The Base64URL transforms a few characters and remove trailing = signs. Need to careful about which format is being used

## Useful resources

### DAML Documentation

[DAML Product Page](https://daml.com)

[DAML Documentation ](https://docs.daml.com)

### OpenSSL, TLS and TLS Testing

https://testssl.sh   # Very good script to perform checks on TLS 

https://jamielinux.com/docs/openssl-certificate-authority/online-certificate-status-protocol.html

https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/

https://akshayranganath.github.io/OCSP-Validation-With-Openssl/

https://medium.com/@KentaKodashima/generate-pem-keys-with-openssl-on-macos-ecac55791373

OpenSSL testing of certs: https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

### JSON Web Tokens

[Introduction to JWT](https://jwt.io/introduction/)

[JWT Handbook](https://auth0.com/resources/ebooks/jwt-handbook) [Requires registration]

[JWT Debugger](https://jwt.io)

### Using GRPCurl

https://prefetch.net/blog/2020/04/22/using-grpcurl-to-interact-with-grpc-applications/

https://bionic.fullstory.com/tale-of-grpcurl/


Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0
