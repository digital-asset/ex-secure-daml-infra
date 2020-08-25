[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Build & Preparation Steps

## Configure your environment

Update the file ```env.sh``` with the following details:

- Auth0 details (Auth0 account and client ID and service account credentials)
- DNS Domain - defaults to ```acme.com```
- Name of Organization for PKI - defaults to ```Acme Corp, LLC```
- Select options for Mutual Auth and whether to use local JWT generated tokens

We default the ```Ledger ID``` (random UUID) and ```Application ID``` ('ex-secure-daml-infra') but these can be changed, though you need to ensure 
they are consistent across services.

## Build the DAML application

```
daml build
```

## Generate the Javascript code from DAML Model
  
We need to generate TypeScript code bindings for the compiled DAML model.
At the root of the repository, run
```
daml codegen js .daml/dist/ex-secure-daml-infra-0.1.0.dar -o daml.js
```
The latter command generates TypeScript packages in the `daml.js` directory.

## Build the React UI
Next, navigate to the `ui` directory and install the dependencies and build the app by running
```
cd ui
yarn install
yarn build
```
The last step is not absolutely necessary but useful to check that the app compiles.

# Next Step

[Starting Services](./StartingServices.md)

Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0
