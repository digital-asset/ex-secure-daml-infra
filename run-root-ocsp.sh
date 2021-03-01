#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# https://jamielinux.com/docs/openssl-certificate-authority/online-certificate-status-protocol.html
# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/
# https://akshayranganath.github.io/OCSP-Validation-With-Openssl/
# https://medium.com/@KentaKodashima/generate-pem-keys-with-openssl-on-macos-ecac55791373

# OpenSSL testing of certs: https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

create_CRL() {
  # Create CRL for certificate

  openssl ca -config $ROOTDIR/certs/root/openssl.cnf \
      -gencrl -out $ROOTDIR/certs/rot/crl/root.crl.pem

  # Check CRL
  openssl crl -in $ROOTDIR/certs/root/crl/root.crl.pem -noout -text
}

create_ocsp_key() {
  echo "Creating OCSP Server Key"

  # Create OCSP 
  openssl genrsa \
      -out $ROOTDIR/certs/root/private/root-ocsp.$DOMAIN.key.pem 4096

  openssl req -config $ROOTDIR/certs/root/openssl.cnf -new -sha256 \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=root-ocsp.$DOMAIN" \
      -key $ROOTDIR/certs/root/private/root-ocsp.$DOMAIN.key.pem \
      -out $ROOTDIR/certs/root/certs/root-ocsp.$DOMAIN.csr.pem

  openssl ca -batch -config $ROOTDIR/certs/root/openssl.cnf \
      -extensions ocsp -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/root/certs/root-ocsp.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/root/certs/root-ocsp.$DOMAIN.cert.pem

  # Validate extensions
  openssl x509 -noout -text \
      -in $ROOTDIR/certs/root/certs/root-ocsp.$DOMAIN.cert.pem
}

start_ocsp() {
  echo "Starting OCSP responder"

  cd $ROOTDIR

  # Note that this is set to only listen for one request and then terminate
  openssl ocsp -port 2562 -text \
    -index "$(pwd)/certs/root/index.txt" \
    -CA "$(pwd)/certs/root/certs/ca.cert.pem" \
    -rkey "$(pwd)/certs/root/private/root-ocsp.$DOMAIN.key.pem" \
    -rsigner "$(pwd)/certs/root/certs/root-ocsp.$DOMAIN.cert.pem" \
    -nrequest 1 &

  sleep 3
}
start_ocsp_longrunning() {
  echo "Starting root OCSP responder"

  cd $ROOTDIR 

  # Note that this is set to only listen for one request and then terminate
  x=1
  while [ $x -le 20 ]
  do
    openssl ocsp -port 2562 -text \
      -index "$(pwd)/certs/root/index.txt" \
      -CA "$(pwd)/certs/root/certs/ca.cert.pem" \
      -rkey "$(pwd)/certs/root/private/root-ocsp.$DOMAIN.key.pem" \
      -rsigner "$(pwd)/certs/root/certs/root-ocsp.$DOMAIN.cert.pem" \
      -multi 1 \
      -timeout 5

    x=$(( $x + 1 ))
  done

}

check_ocsp_response() {
  echo "Check OCSP response"
  openssl ocsp -CAfile "$ROOTDIR/certs/root/certs/ca.cert.pem" \
      -url http://127.0.0.1:2562 -resp_text \
      -issuer "$ROOTDIR/certs/root/certs/ca.cert.pem" \
      -cert "$ROOTDIR/certs/intermediate/certs/intermediate.cert.pem"
}

# On MacOS use brew installed openssl 1.1.1
export PATH=/usr/local/opt/openssl/bin:$PATH

source env.sh

export ROOTDIR=$PWD
cd $ROOTDIR

if [ ! -d certs ] ; then
 echo "ERROR: You need to create PKI CA hierarchy first!"
 exit
fi

if [ ! -f $ROOTDIR/certs/root/private/root-ocsp.$DOMAIN.key.pem ]; then
   create_ocsp_key
fi

start_ocsp
check_ocsp_response

start_ocsp_longrunning



