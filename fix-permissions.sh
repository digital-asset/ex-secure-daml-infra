#/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# We need to fix access permissions for these files when in docker-compose or else services cannot get access to files.

source env.sh

chown -R 0:0 /data
chmod go+rx /data/certs/server/private
chown 999:999 /data/certs/server/private/db.$DOMAIN.key.pem
chown 999:999 /data/certs/server/certs/db.$DOMAIN.cert.pem

chown 101:101 /data/certs/server/private/ledger.$DOMAIN.key.pem
chown 101:101 /data/certs/server/certs/ledger.$DOMAIN.cert.pem

chown 100:100 /data/certs/server/private/envoy.$DOMAIN.key.pem
chown 100:100 /data/certs/server/certs/envoy.$DOMAIN.cert.pem

chown 101:101 /data/certs/server/private/web.$DOMAIN.key.pem
chown 101:101 /data/certs/server/certs/web.$DOMAIN.cert.pem

chown 101:101 /data/certs/client/client1.$DOMAIN.key.pem
chown 101:101 /data/certs/client/client1.$DOMAIN.cert.pem
chmod ugo+r /data/certs/client/client1.$DOMAIN.key.pem
chmod ugo+r /data/certs/client/client1.$DOMAIN.cert.pem

chown -R 101:101 /data/certs/jwt

