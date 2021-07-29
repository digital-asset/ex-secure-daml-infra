[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Getting started

## Tested Configuration
The following configuration was used to create this reference sample:
- Apple laptop with MacOS Catalina 10.15 or Big Sur 11.0 or later
  - IMPORTANT NOTE: This has been tested on Apple MacOS Catalina with OpenSSL 1.1.0. 
  The provided scripts will not work with the default LibreSSL 1.0 supplied by Apple or earlier version of OpenSSL.
- Docker Desktop for Mac 3.1.0(51484) (Engine 20.10.02) 
- Docker Compose 1.27.4
- PostGres 12 on Docker
- NGINX 1.19.1 on Docker
- Envoy Proxy 1.15 on Docker
- DAML 1.15.0
- Python 3.9.1

## Prerequisites

Before you can run the application, you need to install:
- [brew](https://brew.sh/) package manager for MacOS
- the [yarn](https://yarnpkg.com/en/docs/install) package manager for JavaScript.
- grpcurl - to test secure GRPC calls 
- jq - for JSON parsing 
- openssl 1.1.1j - for PKI, TLS 1.3 and any other aspects
- Docker - to run postgres and nginx proxy
- Python - jwcrypto library

```$xslt
brew install jq grpcurl openssl node
```

## Install DAML SDK

[DAML Installation Steps](https://docs.daml.com/getting-started/installation.html)

## Clone Git repo

```$xslt
git clone git@github.com:digital-asset/ex-secure-daml-infra.git
```

## Python dependencies

```
pip3 install jwcrypto
```

## Repository layout

- Project root-dir
  - /bot - Bot sample code
  - /certs - Created by scripts to contain PKI and JWT tokens
  - /daml - sample DAML application files for Model, Scripts and Triggers
  - /nginx-conf - NGINX configuration
  - /static-content - HTML static content (not used)
  - /ui - front-end code
  - /Documentation - this set of documentation

# Two sample variants

We provide two variants of this sample.
- Local execution of each service individually through a sequence of startup scripts
- A Docker-compose environment that spins up all relevant nodes in one go

The first option allow greater visibility into the operation of the component services. The docker-compose environment allows 
repeatable startup and a test node to run specific tests against the environment. 

# Configuring your example application enviroment

## Configuration Options - ```env.sh```
The provided scripts make use of a file ```env.sh``` to manage some standard settings used throughout this application. You can change these parameters in the file.

```$xslt
# The Ledger ID is used to bootstrap the system with a known identity. This is a random UUID and should be unique to each ledger instance.
#
# PLEASE CHANGE FOR YOUR OWN USE!!
LEDGER_ID="2D105384-CE61-4CCC-8E0E-37248BA935A3"

# The following define the domain names of the PKI infrastructure
DOMAIN=acme.com
DOMAIN_NAME="Acme Corp, LLC"

#The following options define whether to enable client certificate authentication. Please uncomment one
#CLIENT_CERT_AUTH=FALSE
CLIENT_CERT_AUTH=TRUE

# Following options will use a local signing key rather than Auth0
LOCAL_JWT_SIGNING=FALSE
#LOCAL_JWT_SIGNING=TRUE

# The following options relate to Auth0 setup and service credentials. Please see documentation for meaning
AUTH0_DOMAIN="<Set-to-name-of-your-Auth0-instance>"
AUTH0_CLIENT_ID="<Client-id-configured-for-your-auth0-instance>"

M2M_CLIENT_ID='<client-id-for-account>'
M2M_CLIENT_SECRET='<client-secret-for-account>'

SCRIPT_CLIENT_ID='<client-id-for-account>'
SCRIPT_CLIENT_SECRET='<client-secret-for-account>'

TRIGGER_CLIENT_ID='<client-id-for-account>'
TRIGGER_CLIENT_SECRET='<client-secret-for-account>'

NAVIGATOR_CLIENT_ID='<client-id-for-account>'
NAVIGATOR_CLIENT_SECRET='<client-secret-for-account>'

JSON_CLIENT_ID='<client-id-for-account>'
JSON_CLIENT_SECRET='<client-secret-for-account>'

ALICE_CLIENT_ID='<client-id-for-account>'
ALICE_CLIENT_SECRET='<client-secret-for-account>'

BOB_CLIENT_ID='<client-id-for-account>'
BOB_CLIENT_SECRET='<client-secret-for-account>'

GEORGE_CLIENT_ID='<client-id-for-account>'
GEORGE_CLIENT_SECRET='<client-secret-for-account>'

# Check latest version of file for full set of options
```

## Configure Local DNS

To run the non-Docker-Compose samples you need to configure some DNS names for you local services. This ensures that TLS certificates work properly.
Run the following command

```$xslt
sudo vi /etc/hosts
```
and add a line entry for

```$xslt
127.0.0.1 web.acme.com db.acme.com ledger.acme.com jsonapi.acme.com envoy.acme.com ocsp.acme.com
```

Note that Docker config is specific to the Mac as it uses Mac specific names to access the hosts localhost IP.

Docker-compose setup uses internal network aliases to allow connections between services so the above is not required.

# Next Step

[PKI Setup](./PKISetup.md)

Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0
