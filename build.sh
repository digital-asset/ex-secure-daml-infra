#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

# DAML Model

daml build  --output dist/ex-secure-daml-infra-0.0.1.dar

# Frontend
if [ 'TRUE' == "$DOCKER_COMPOSE" ] ; then
  PROXY_HOST="web.$DOMAIN"
  EDGE_TARGET="ledger.$DOMAIN"
else
  PROXY_HOST="web.$DOMAIN"
  EDGE_TARGET="docker.for.mac.localhost"
fi

if [ 'TRUE' == "$DOCKER_COMPOSE" ] ; then
  cat edge-tls.yaml-cicd-template | sed -e "s;<EDGE_TARGET>;$EDGE_TARGET;g" | sed -e "s;<DOMAIN>;$DOMAIN;g" > edge-tls.yaml
  #docker build -t authnode:latest -f ./Dockerfile.authnode .
else
  cat edge-tls.yaml-template | sed -e "s;<EDGE_TARGET>;$EDGE_TARGET;g" | sed -e "s;<DOMAIN>;$DOMAIN;g" > edge-tls.yaml
fi

if [ 'TRUE' == "$DOCKER_COMPOSE" ] ; then
  cat ./nginx-conf/nginx.conf-cicd-template | sed -e "s;<DOMAIN>;$DOMAIN;g" > ./nginx-conf/nginx.conf
else
  cat ./nginx-conf/nginx.conf-template | sed -e "s;<DOMAIN>;$DOMAIN;g" > ./nginx-conf/nginx.conf
fi

cat ui/package.json-template | sed -e "s;<PROXY_HOST>;$PROXY_HOST;g" > ui/package.json
cat ui/src/auth_config.json-template | sed -e "s;<AUTH0_DOMAIN>;$AUTH0_DOMAIN;g" -e "s;<AUTH0_CLIENT_ID>;$AUTH0_CLIENT_ID;g" > ui/src/auth_config.json

cd ui
npm install
npm run build

cd ..
if [ ! -d logs ] ; then
  mkdir logs
fi
