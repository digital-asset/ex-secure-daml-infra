#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# set -e

source env.sh

./make-certs.sh

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then
   echo "Using local signing of JWT"
   ./make-jwt.sh
fi

# Start up Postgres in Docker

docker stop daml-postgres
docker rm daml-postgres
docker run --name daml-postgres -d -p 5432:5432 \
  -e POSTGRES_PASSWORD="ChangeDefaultPassword!" \
  -e POSTGRES_HOST_AUTH_METHOD="scram-sha-256" \
  -e POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256 --auth-local=scram-sha-256" \
  -v "$(pwd)/certs/server/certs/db-chain.$DOMAIN.cert.pem:/var/lib/postgresql/db.$DOMAIN.cert.pem:ro" \
  -v "$(pwd)/certs/server/private/db.$DOMAIN.key.pem:/var/lib/postgresql/db.$DOMAIN.key.pem:ro" \
  -v "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem:/var/lib/postgresql/ca-chain.crt:ro" \
  -v "$(pwd)/pg-initdb:/docker-entrypoint-initdb.d:ro" \
  postgres:13 \
  -c ssl=on \
  -c ssl_cert_file=/var/lib/postgresql/db.$DOMAIN.cert.pem \
  -c ssl_key_file=/var/lib/postgresql/db.$DOMAIN.key.pem \
  -c ssl_ca_file=/var/lib/postgresql/ca-chain.crt \
  -c ssl_min_protocol_version="TLSv1.2" \
  -c ssl_ciphers="HIGH:!MEDIUM:+3DES:!aNULL"

# Old version pre-CIS Hardening for reference
#docker run --name daml-postgres -d -p 5432:5432 -e POSTGRES_PASSWORD="ChangeDefaultPassword!" -e POSTGRES_HOST_AUTH_METHOD=trust -v "$(pwd)/certs/server/certs/db.$DOMAIN.cert.pem:/var/lib/postgresql/db.$DOMAIN.cert.pem:ro" -v "$(pwd)/certs/server/private/db.$DOMAIN.key.pem:/var/lib/postgresql/db.$DOMAIN.key.pem:ro" -v "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem:/var/lib/postgresql/ca-chain.crt:ro" postgres:12 -c ssl=on -c ssl_cert_file=/var/lib/postgresql/db.$DOMAIN.cert.pem -c ssl_key_file=/var/lib/postgresql/db.$DOMAIN.key.pem -c ssl_ca_file=/var/lib/postgresql/ca-chain.crt -c ssl_min_protocol_version="TLSv1.2" -c ssl_ciphers="HIGH:!MEDIUM:+3DES:!aNULL"

# Run NGINX

# https://fardog.io/blog/2017/12/30/client-side-certificate-authentication-with-nginx/

docker stop daml-nginx
docker rm daml-nginx

docker run --name daml-nginx -p 8000:8000 -p 443:443 -p 8443:8443 \
  -v "$(pwd)/nginx-conf/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/ui/build:/data/ui/build:ro" \
  -v "$(pwd)/certs/server/certs/web-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/server/private/web.$DOMAIN.key.pem:/etc/ssl/server.key:ro" \
  -v "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -P -d nginx:1.19.1-alpine

# Run Envoy Proxy

docker stop daml-envoyproxy
docker rm daml-envoyproxy
docker run --name daml-envoyproxy -p 10000:10000 -d \
  -v "$(pwd)/edge-tls.yaml:/etc/edge.yaml:ro" \
  -v "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem:/etc/ssl/certs/ca-chain.crt:ro" \
  -v "$(pwd)/certs/client/client1.$DOMAIN.cert.pem:/etc/ssl/client.crt:ro" \
  -v "$(pwd)/certs/client/client1.$DOMAIN.key.pem:/etc/ssl/client.key:ro" \
  -v "$(pwd)/certs/server/certs/envoy-chain.$DOMAIN.cert.pem:/etc/ssl/server.crt:ro" \
  -v "$(pwd)/certs/server/private/envoy.$DOMAIN.key.pem:/etc/ssl/server.key:ro" \
  envoyproxy/envoy-alpine:v1.15-latest \
  -c "/etc/edge.yaml" \
  -l debug


