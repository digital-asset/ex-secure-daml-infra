#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

ROOTDIR=$PWD

#The following options define whether to enable client certificate authentication. Please uncomment one
#CLIENT_CERT_AUTH=FALSE
CLIENT_CERT_AUTH=TRUE

# Following options will use a local signing key rather than Auth0
#LOCAL_JWT_SIGNING=FALSE
LOCAL_JWT_SIGNING=TRUE

# OCSP Checking
OCSP_CHECKING=""
#OCSP_CHECKING="--cert-revocation-checking true"

#DOCKER_COMPOSE=TRUE
DOCKER_COMPOSE=FALSE

DOCKER_IMAGE="digitalasset/daml-sdk:1.16.0"

# The Ledger ID is used to bootstrap the system with a known identity. This is a random UUID and should be unique to each ledger instance.
#
# PLEASE CHANGE FOR YOUR OWN USE!!
LEDGER_ID="2D105384-CE61-4CCC-8E0E-37248BA935A3"

# The following define the domain names of the PKI infrastructure
DOMAIN=acme.com
DOMAIN_NAME="Acme Corp, LLC"

