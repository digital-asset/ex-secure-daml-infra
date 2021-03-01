[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Final Thoughts

This reference application has demonstrated that it is possible to deploy and secure a DAML Ledger. We covered network connection security
using TLS and client certificates. We discussed how to format and use JWT tokens to ensure appropriate actions taken by users and services. 

We did not cover many advanced topics, including:

- Distributed Ledgers and the associated security, deployment and operation concerns
  - DAML supports deployments on a wide variety of ledgers ( [Supported Platforms](https://daml.com/) )
- Full Identity Management, and User and Service Account Provisioning
  - Identity & Package Management is discussed in our documentation [Identity & Package Management](https://docs.daml.com/concepts/identity-and-package-management.html)
  - Certificate and JWT renewal and revocation
- KYC (Know Your Customer) and many other business workflow concerns. These can be implemented in DAML.
- Using Envoy Proxy to add:
  - Denial-Of-Service (DOS) Protection via rate limiting
  - Audit logging of connection and commands
  - Further capabilities for the external facing interfaces

Many of these aspects will depend significantly on the type of application you are developing and the risk tradeoffs you need to make to 
secure your use case. Many also depend on business level workflows that may be modelled directly in the DAML Model itself.

## How to get help

We love to receive feedback on our products and these reference applications. 

- Feel free to ask ```Questions``` on our [DAML Community Form](https://discuss.daml.com/c/questions/5).
- We are also available on [DAML Driven Slack](https://damldrive.slack.com)
- Contact Us if you need Enterprise level support for DAML.

Some notes on the implementation are available: [Implementation Notes](./ImplementationNotes.md)

Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0





