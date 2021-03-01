#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

docker stop daml-nginx
docker stop daml-postgres
docker stop daml-envoyproxy
docker rm daml-postgres
docker rm daml-nginx
docker rm daml-envoyproxy
killall -9 openssl

rm dist/*
rm -rf certs
rm logs/*
rm output.txt
rm edge-tls.yaml
rm nginx-conf/nginx.conf
rm sandbox.log
rm -rf ui/build
rm ui/package.json
rm -rf ui/node_modules
rm navigator.log
rm script-output.txt
rm *.jar
rm client-app/client.jar
rm -rf client-app/target
rm -rf client-app/project/project
rm -rf client-app/project/target
rm socket/client/*.class
rm socket/server/*.class
