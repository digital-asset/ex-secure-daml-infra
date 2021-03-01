[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# Auth0 Setup

We use Auth0 as this provides an oAuth compliant identity and authentication service. It provides 
rules and hooks to allow custom claims to be provided into JWT tokens. Other oAuth provides should 
work as well.

# Sign up for Auth0 Trial

High level steps for seting up authentication include:
- Signup for Auth0 Trial Account
- Configure API and Primary Web Application (React)
- Setup User Authentication
- Setup Application Authentication

# Setup API & Primary Web Application

Steps to create an "API" in Auth0

- Create New API
- Provide a name (```ex-secure-daml-infra```)
- Provide an Identifier (```https://daml.com/ledger-api```)
- Select Signing Algorithm of ```RS256```

To create the primary web application (that end-users will sign into)
- Create new Application
- Select Single Page Application
- Select React
- In App Settings:
    - Set Allowed CallBack URLS, Allowed Logout URLS, Allowed Web Origins: 
        - ```http://localhost:3000, https://web.acme.com```

# Setup User Authentication

## Create Rules
Auth0 uses Rules to allow custom claims to be added to generate JWT tokens for end-users. We also use it to configure metadata 
automatically on first registration. We need to create two rules"

- "Onboard user to Ledger"
- "Add Ledger API Claims"

For each rule:

- Create a new rule, 
- Select "Empty Rule:
- Name it appropriately
- Paste the rule template code for each (see below).

### Rule: "Onboard user to ledger"

```$xslt
function (user, context, callback) {
  // Only support users with a verified email address
  if (!user.email || !user.email_verified) {
    return callback(null, user, context);
  }
  // Only onboard the user to the ledger once
  if (user.app_metadata && user.app_metadata.daml_ledger_api) {
  	return callback(null, user, context);
  }
  // Construct the the DAML party identifier from the email
  // We could also use a random UUID string here
  var partyIdentifier = user.email.replace(/\W/gi, "-");

  // TODO: Allocated the party on the ledger
  // This step is handled in DAML Script to initialise the test ledger
  // Production deployments would need to manage flow and sync of identity

  // Save the new app metadata
  user.app_metadata = user.app_metadata || {};
  user.app_metadata.daml_ledger_api = {
    partyIdentifier
  };
  auth0.users.updateAppMetadata(user.user_id, user.app_metadata)
    .then(function(){
        callback(null, user, context);
    })
    .catch(function(err){
        callback(err);
    });
}
```

### Rule: "Add Ledger API Claims"
```$xslt
function (user, context, callback) {
  // Hardcoded constants
  var ledgerId = 'daml-auth0-example-ledger';
  var applicationId = 'daml-auth0-example';
  
  // Read the DAML party identifier from the app metadata
  var actAs = [];
  if (user.app_metadata && user.app_metadata.daml_ledger_api) {
    actAs = [user.app_metadata.daml_ledger_api.partyIdentifier];
  }
  
  // Add ledger API claims to the token
  var namespace = 'https://daml.com/ledger-api';
  context.accessToken[namespace] = {
    "ledgerId": ledgerId,
    "applicationId": applicationId,
    "actAs": actAs,
    "admin": false,
  };
  callback(null, user, context);
}
```
## Create Users

To allow you to login as the example users, ```"Alice"``` and ```"Bob"``` you need to create
two users in Auth0. Steps include 

- Create a New User
- Enter Email and your preferred (strong) passphrase
- If using local Username / Password database, set connection to ```Username-Password-Authentication```. 
- In the app_metadata section of the User, add the following template. You will need to adjust per user so that ```partyIdentifier```
matches that name of the user in the Ledger, i.e. "Alice", "Bob"

User Metadata
```$xslt
{
  "daml_ledger_api": {
    "partyIdentifier": "Alice"
  }
}
```

Auth0 also supports
connections from many social media and Enterprise authentication sources. You can use these to provide SSO to existing authentication
services in your company. Mapping of social accounts to Ledger via metadata is left as an exercise.

# Setup Service Account (M2M) Authentication

In Auth0, Machine-2-Machine accounts or Service Accounts allow backend batch applications to 
obtain longer lived service credentials using oAuth Client Credentials Exchange authentication. The
service sends its Client ID and Secret to Auth0 and is issued a token. Services can then operate 
based on the rights issued to that service, i.e. act on behalf of a user. 

Auth0 Hook for Client Credentials flows is defined below. This hook adds a custom claim for each service, where
the claim contents is managed as Application Metadata. This allow differing claims for each account.

## Create Hook for Client Credentials

Create a Hook in Auth0 and provide a name, and select Client Credential Exchange as the Hook Type. Edit the Hook 
and add the Hook script below and save contents. This hook allows exact metadata for each account to be managed as part of
account's metadata in Auth0.

```$xslt
/**
@param {object} client - information about the client
@param {string} client.name - name of client
@param {string} client.id - client id
@param {string} client.tenant - Auth0 tenant name
@param {object} client.metadata - client metadata
@param {array|undefined} scope - array of strings representing the scope claim or undefined
@param {string} audience - token's audience claim
@param {object} context - additional authorization context
@param {object} context.webtask - webtask context
@param {function} cb - function (error, accessTokenClaims)
*/
module.exports = function(client, scope, audience, context, cb) {
  var tmp_string = "";
  var token;
  tmp_string = String(client.metadata.token);
  token = JSON.parse(tmp_string);
  
  // Claims to be added for JSON API Gateway
  var access_token = {};
    // Claims for DAML - Note values come from Applicatin Metadata
  access_token['https://daml.com/ledger-api'] = {
    "ledgerId": '2D105384-CE61-4CCC-8E0E-37248BA935A3',
    "applicationId": token["application_id"],
    "actAs": token["actAs"],
    "readAs": token["readAs"],
    "admin": token["admin"]
  };
  console.log(access_token);
  cb(null, access_token);
};

```

Note the Ledger ID is for this sample and you would need to change for other dpeloyments.

## Create Service Accounts (Machine-2-Machine) accounts

We now need to create sample Service Accounts for each service we need. This includes:

- HTTP JSON API Service (daml-json)
- A Service Account per Party (daml-alice, daml-bob, any other parties you want to test)
- A Script Runner service account to allow scripts to run (daml-script)
- A Trigger service for Bob to run test Trigger (daml-trigger)
- A Navigator service to run test Navigator /Console (daml-navigator)
- A test service with rights to run as several Parties (daml-m2m)

For each account, you need to:

- Create account and give the name above
- Add Account metadata for claims. This is a key / value pair, with a key of ```token``` and value 
of the format below. 
    - Account metadata is added under ```Advanced Settings``` at bottom of Seetings page.

### Account Metadata format
Party specific - e.g. "Alice", "Bob"
```$xslt
token: {"application_id": "ex-secure-daml-infra", "admin": false, "actAs": ["Alice"], "readAs": ["Alice"] }
```
### HTTP-JSON-API-Gateway
This is a read-only account that is used by JSON API Gateway to retrieve package information from the Ledger.
Commands executed through the JSON API used the token supplied from the application. 
```$xslt
token: {"application_id": "HTTP-JSON-API-Gateway", "admin": false, "actAs": [], "readAs": [] }
```

### Navigator
This is a specific format account for DAML Triggers (no application ID). We plan to make this more flexible in 
the future. NOTE: Navigaot is considered a development time tool. The tool currently generates a random
applicationId and thus you need a token which does not restrict to a specific appID to enable this to work. This
may change in the future. 
```$xslt
token: {"admin": true, "actAs": ["Alice", "Bob"], "readAs": ["Alice", "Bob"] }
```

### M2M account
A Service Account that run as all the defined parties on the ledger. Not you would need to update ```actAs``` and ```readAs```
arrays as you provision additional users onto the Ledger.
```$xslt
token: {"application_id": "ex-secure-daml-infra", "admin": true, "actAs": ["Alice", "Bob"], "readAs": ["Alice", "Bob"] }
```

## Remember to update the ```env.sh``` file

You will need to copy the Client ID and Client Secret for each account into the 
```env.sh``` file so that the relevant scripts have the correct credentials to authenticate and 
retrieve the necessary token.

# Recap of these Steps

Authentication Services often require many steps to confirm and manage credentials. In the above:

- We created a web application for end-user authentication
- We defined an API that is accessed by end-users and services accounts
- We setup users and Rules to add custom claims for DAML Ledger
- We setup service accounts for automated actions on behalf of these users and a Hook to add relavant
claims to each account on logon.

To retrieve a specific credential use the ```./get-<name>-token.sh``` scripts

# How to get JWT/JWKS without Auth0

We have provided an option in ```env.sh``` to switch to a locally generated JWT implementation. This creates a
signing key from the local PKI and a set of script to generate the JKWS and JWT files. This allows for more
automated testing, for example CI/CD.

# Next Step

[Build DAML Application](./BuildSteps.md)

Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0


 