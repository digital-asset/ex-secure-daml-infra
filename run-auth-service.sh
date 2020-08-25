#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

# Parameters
# 1 - signing private key
# 2 - JWKS token
# 3 - Service Accounts JSON Lookup
# 4 - Ledger ID
# 5 - TLS private key
# 6 - TLS Public chain
python3 auth-service.py "./certs/signing/jwt-sign.acme.com.key.pem" ./certs/jwt/jwks.json "./accounts.json" $LEDGER_ID "./certs/server/private/auth.$DOMAIN.key.pem" "./certs/server/certs/auth-chain.$DOMAIN.cert.pem"

