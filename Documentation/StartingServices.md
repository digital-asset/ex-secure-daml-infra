[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# How to run components

To start the full system involves the following steps:

- Start the database and web proxy and build the PKI Infrastructure
- Start the Ledger Server
- Start the JSON API
- Start the web application backend
- (Optional) Start DAML Navigator
- Initialise the Ledger with intial users and contracts

# Partial Docker or Docker-Compose?

Options are provided below for a non-Docker Ledger (only POstgres, NGINX and Envoy in Docker) or a full Docker Compose based startup (see section at bottom)

# Starting services (Non-Docker based Ledger steps)
## Initial PKI setup, database and NGINX Proxy and Ledger start 
In one terminal in the root directory, start a DAML ledger using ```run-docker.sh``` and ```run-sandbox.sh```. 

The Docker scripts start a container for:
- Postgres Database
- NGINX proxy in front of JSON API and a web server in front of yarn
- an Envoy GRPC Proxy in from of Ledger Server for external connections

WARNING: The ./run-docker script will delete the existing database and PKI and rebuild these. If you want to retain the existing 
PKI and data in your Ledger, do not run this step.
```
./run-docker.sh        # WARNING: This deletes the PKI and Docker containers and thus loses current certificates and Ledger data
./run-sandbox.sh
```
This must continue running to serve ledger requests.
## JSON API Server
In a second terminal window, in the project root directory, start the JSON API (after Ledger Server is up and available)
```$xslt
./run-json-api.sh
```
## YARN Web Application
In a third terminal window, in the project root directory, start the Yarn backend
```$xslt
./run-frontend.sh
```

## Initializing the Ledger

At this point the ledger is now running but has no Parties or data. Ledger Server will have imported the
default ```dar``` file containing the currently built DAML Model. The following bash script executes
```DAML Script``` to run an initialisation script that allocated two default parties ("Alice" and "Bob"), creates 
some initial contracts and executes actions against those contracts. You can change this by updating the 
```Setup.daml``` and ```initialize``` function. 

```$xslt
./init-ledger.sh
```

## Starting the Trigger

This step starts a Trigger on behalf of Party ```Bob```. The trigger waits for new contracts for Bob and 
then ```Give```'s these to Alice.

```$xslt
./run-trigger.sh
```

## Starting the Python dazl-client Bot

This step starts a dazl-client Python bot on behalf of Party ```George```. The bot waits for new contracts for 
George and then ```Give```'s these to Alice.

NOTE: The dazl-client library uses oAuth to retrieve a JWT token for the service. The sample can be configured to use Auth0 or a 
local test oAuth service handler. This required dazl-client later than 7.02.

```$xslt
# Following only required if not using Auth0 - i.e. CI/CD automation testing
./run-auth-service.sh

# This runs the actual bot
./run-python-bot.sh
```

## (Optional) DAML Navigator
(Optionally) In a fourth terminal window, in the project root directory, start the Navigator application. This
is mainly used in development to see existing contracts on the Ledger and perform commands.
```$xslt
./run-navigator.sh
```

DAML SDK also offers ```Navigator Console``` and ```DAML REPL``` for more interactive work on the Ledger.

# Starting Services (docker-compose option)

```aidl
# Install local DNS settings
# Update env.sh file to set DOCKER_COMPOSE settings and / or local JWT
./clean.sh
./build.sh
./run-docker-compose.sh
./rundocker-tests.sh
./compose-shutdown.sh
```

Note that to accommodate CircleCI automated builds the files are copied from the local directory to a named Docker volume. This
means that the test environment will need to be restarted to see changes. Tests can be performed against exposed services if 
configuration (configs, certs, JWT, etc) do not need to be changed. 

# Next Step

You can now test out your running ledger 

[Testing](./Testing.md)


Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0
