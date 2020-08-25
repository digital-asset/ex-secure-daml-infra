#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

source env.sh

./make-certs.sh

if [ "TRUE" == "$LOCAL_JWT_SIGNING" ] ; then
  ./make-jwt.sh
else
  ./get-tokens.sh
fi

docker volume create data
docker run -d -i -t -v data:/data --name=data-uploader alpine:latest sh
echo "Copy data to Docker volume..."
docker cp . data-uploader:/data
echo "Fixing permissions..."
docker exec -it data-uploader sh -c "cd data; ./fix-permissions.sh"
docker stop data-uploader
#docker ps -a
#docker volume ls
docker-compose --env-file=docker-compose.env up -d
#docker ps -a
#docker inspect ex-secure-daml-infra_daml-testnode_1
#docker-compose --env-file=docker-compose.env up



