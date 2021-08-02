#!/bin/sh -xe
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

apk update
apk add openssl jq bash curl python3 

apk --no-cache add openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
apk add --update coreutils && rm -rf /var/cache/apk/*

curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.8.2/grpcurl_1.8.2_linux_x86_64.tar.gz -o /tmp/grpcurl_1.8.2_linux_x86_64.tar.gz
cd /tmp
tar xvfx grpcurl_1.8.2_linux_x86_64.tar.gz
mv grpcurl /usr/local/bin/grpcurl
chmod u+x /usr/local/bin/grpcurl

cd ~
export TERM=xterm-256color
curl -sSL https://get.daml.com/ | sh /dev/stdin  1.15.0

export PATH=/root/.daml/bin:/usr/local/bin:$PATH
cd /data

set +e
bash -x ./test-tls.sh 2>&1 > logs/test-tls.log
bash -x ./test-grpc.sh 2>&1 > logs/test-grpc.log
bash -x ./test-json.sh 2>&1 > logs/test-json.log
bash -x ./test-script.sh 2>&1 > logs/test-script.log


