[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Welcome to _Secure DAML Infrastructure_

This repository contains a reference implementation of how to setup a DAML Ledger with full "Infrastructure" security, 
i.e. secure connections over TLS and connection authorization via tokens. This will involve a test 
Public Key Infrastructure (PKI) to create TLS and client certificates and JSON Web Token (JWT) for all 
user and service authentication. We will use [Auth0](https://www.auth0.com) as an example of an oAuth provider for this, 
though the concepts should work with a number of others, e.g.Okta, OneLogin, Ping. 

The demo application covers the following aspects:

1. Create a reference PKI with root and intermediate CAs and TLS certificates
2. Integrate security with Auth0 for user and service accounts (M2M)
3. Configure TLS security for all connections including database
4. A UI written in [TypeScript](https://www.typescriptlang.org/) and [React](https://reactjs.org/) authenticating 
through Auth0
5. A series of tests to demonstrate the services running over secure connections
6. Test DAML Triggers and Python bots for DAML automation

This builds on the original sample [ex-authentication-auth0](https://github.com/digital-asset/ex-authentication-auth0) 
that was described in 
blog: [Easy authentication for your distributed app with DAML and Auth0](https://daml.com/daml-driven/easy-authentication-for-your-distributed-app-with-daml-and-auth0/)

## Getting started

[Documentation](./Documentation/README.md) is also provided detailing each of the steps.

Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0




