[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Welcome to _Secure DAML Infrastructure_

This repository contains an example implementation of a secure DAML Ledger with full "Infrastructure" security, 
i.e. secure connections over TLS and application authorization via tokens. This will involve:
 
- a Public Key Infrastructure (PKI) to create TLS and client certificates
- Base Network Connectivity Security via TLS and client certificates
- JSON Web Token (JWT) for all user and service authentication 

We will use [Auth0](https://www.auth0.com) as an example of an oAuth provider for this, 
though the concepts should work with a number of others, e.g. Okta, OneLogin, Ping. This allows connections
to public social media Identity services, including Google, Facebook, LinkedIn, etc. 

We do not attempt to demonstrate complex DAML workflows as these are covered in other Reference Applications. We also use a single PostgresQL 
database as the peristence tier. This can be replaced with a full Distributed Ledger implementation but that is not covered
in this sample. 

## Disclaimer

This sample is for reference and is not intended as a production ready deployment. The intent is to demonstrate the setup and operation of infrastructure level security for a
DAML Ledger and to explain the relevant concepts and terms used.  

## Background Knowledge

This sample assumes some knowledge of infrastructure and network security. The Core Concepts are covered here:

- [Core Concepts](./CoreConcepts.md)

## Sequence of Steps

The sample is setup and run through the following steps:

1. Create a reference PKI with root and intermediate CAs and TLS Server and Client Certificates
2. Integrate security with Auth0 for user and service accounts (M2M)
3. Configure TLS security for all connections including database
4. A UI written in [TypeScript](https://www.typescriptlang.org/) and [React](https://reactjs.org/) authenticating through Auth0
5. A variety of tests to demonstrate secure applications and connectivity

- [Getting Started](./GettingStarted.md)
- [Setting up PKI and certificates](./PKISetup.md)
- [Setting up Auth0](./Auth0Setup.md)
- [Build & Configure Application](./BuildSteps.md)
- [Starting Services](./StartingServices.md)
- [Testing](./Testing.md)
- [Next Steps & Resources](./NextSteps.md)
- [Implementation Notes](./ImplementationNotes.md)

## TechNotes / Interesting topics

- [Postgres Database Hardening](./technote-postgresql.md)

Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0


