#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

source env.sh

docker-compose exec daml-testnode sh -c "cd /data; ./test-all.sh > logs/test-all.log"

docker cp data-uploader:/data/logs .


