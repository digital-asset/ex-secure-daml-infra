[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Testing the Application and Services

We provide a number of examples of how to interact with a secure Ledger. These include:
- Demonstrate secure Web Application
- Demonstrate secure Navigator
- Demonstrate access to JSON and API, and GRPC
- Demonstrate secure DAML Scripts
- Demonstrate secure DAML Triggers

## Exposed Ports & Services

The following tables detailed the exposed services and ports.

| Service           | Port    | Protocol       |
| ----------------- | -------:| ---------------|
| Ledger Server     | 6865    | (m)TLS/GRPC    |
| NGINX - UI (Fronts Yarn)       | 443     | TLS/HTTP1.1    |
| NGINX - JSON (Fronts JSON API Service)      | 8000    | TLS/HTTPS1.1   |
| Envoy GRPC (Fronts Ledger API)        | 10000   | TLS/GRPC       |
| Native JSON       | 7575    | HTTP           |
| Native Yarn UI    | 3000    | HTTP           |
| Navigator         | 4000    | HTTP           |

## Web Application

To access the web application point your browser to https://server.acme.com. Your browser may state that this is insecure but 
this is due to browser not trusting this private Root CA. You can import the Root CA public Key if required, but this needs to 
happen each time you rebuild the PKI.  

You should be redirected to Auth0 to 
authenticate your user and then be able to see your user profile and any active contracts for that user. The web application
also display your access token for other testing as your logged in user.

NOTE: In local JWT mode, Web Application is unusable at this time.

## Testing JSON API

For simplicity we provide a test script that uses the ```curl``` command to call the JSON API. The script does the following:
- Queries for all known parties
- Queries for all packages deployed to ledger
- (If configured) creates a new contract as a user and then executes a choice to transfer to "George" 

```
./test-json.sh
```
Full JSON APi Documentation is available here: [JSON API](https://docs.daml.com/json-api/index.html)

## Testing GRPC

To demonstrate that GRPC can be access securely we use the ```grpcurl``` command. This is similar to ```curl``` but
make calls over HTTP2 and GRPC. Ledger Server has enabled GRPC reflection and thus allows clients to look up offered service endpoints.

```$xslt
./test-grpc.sh
```

Tests prove connection and authentication but executing commands is left as an exercise for the reader.

## Test DAML Scripts

DAML Scripts can be used for Ledger initialization and other batch / bulk actions.  

The test script calls into a second example Script to perform similar actions to the JSON test above. However, this uses DAML Script
to show that you can use DAML throughout your application.

```$xslt
./test-script.sh
```

Navigator Console and DAML REPL are also available for ad-hoc access to the DAML Ledger.

## Testing TLS

This test uses openssl to dump out details of the TLS negotiation to the web server, the Ledger and the database.

```aidl
./test-tls.sh
```

You can also use tests like [testssl.sh](https://testssl.sh) that a provides a very comprehensive scan of TLS settings and 
checks for weaknesses. 

## Testing local JWT / JWKS tokens

By changing the settings in ```env.sh``` it is possible to use locally signed JWT tokens. The scripts:
 - generatea an RSA signing key from the local PKI
 - generates the associated JWKS set
 - creates tokens for all Parties using ```RS256``` JWT signing
 - allows authentication testing without using Auth0. 
 
This option might be used for automated testing in CI/CD without Auth0, though without end-user authentication testing of 
the web server. An option for the reader might include testing with open-source oAuth providers.

We have provided some sample scripts to generate and decode JWT / JWKS format files. These are helpful for debugging authentication
and to avoid needing to post any data to public web sites. For non-critical tokens, you can also use [JWT Debugger](https://jwt.io) to 
decode and validate signatures. This is NOT RECOMMENDED for production tokens. 

```aidl
./decode-jwt.sh <filename> # decode a JWT file and shows header and payload
./decode-jwks.sh # depending on settings display Auth0 or local JWKS file and certificates

./get-tokens.sh - when configured for Auth0 pulls all service tokens
./make-jwt.sh # when configured for local JWT, creates local JWT tokens
```

# Next Step
 [Final Thoughts and Next Steps](./NextSteps.md)
 
Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0

 