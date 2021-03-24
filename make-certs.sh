#!/bin/bash
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

# https://jamielinux.com/docs/openssl-certificate-authority/online-certificate-status-protocol.html
# https://www.shellhacks.com/create-csr-openssl-without-prompt-non-interactive/
# https://akshayranganath.github.io/OCSP-Validation-With-Openssl/
# https://medium.com/@KentaKodashima/generate-pem-keys-with-openssl-on-macos-ecac55791373

# OpenSSL testing of certs: https://www.feistyduck.com/library/openssl-cookbook/online/ch-testing-with-openssl.html

clean_directory() {
  rm -rf certs
}

create_root() {
  echo "Creating Root Key"
  cd $ROOTDIR

  # Make Root Directory tree
  mkdir -p certs/root
  cd $ROOTDIR/certs/root

  mkdir certs crl newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial

  cat $ROOTDIR/root-ca.cnf.sample | sed -e "s;<ROOTDIR>;$ROOTDIR;g" -e "s;<DOMAIN>;$DOMAIN;g" -e "s;<DOMAIN_NAME>;$DOMAIN_NAME;g" > $ROOTDIR/certs/root/openssl.cnf

  # Generate Root CA private key
  openssl genrsa -out $ROOTDIR/certs/root/private/ca.key.pem 4096
  chmod 400 $ROOTDIR/certs/root/private/ca.key.pem

  # Create Root Certificate (self-signed)
  openssl req -config $ROOTDIR/certs/root/openssl.cnf \
      -key $ROOTDIR/certs/root/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=root-ca.$DOMAIN" \
      -out $ROOTDIR/certs/root/certs/ca.cert.pem

  # Dump out cert details
  openssl x509 -noout -text -in $ROOTDIR/certs/root/certs/ca.cert.pem

}

create_intermediate() {
  echo "Creating Intermediate Key"

  cd $ROOTDIR
  # Create Intermediate CA directory tree
  mkdir -p certs/intermediate
  cd certs/intermediate

  mkdir certs crl csr newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial
  echo 1000 > crlnumber

  cat $ROOTDIR/intermediate-ca.cnf.sample | sed -e "s;<ROOTDIR>;$ROOTDIR;g" -e "s;<DOMAIN>;$DOMAIN;g" -e "s;<DOMAIN_NAME>;$DOMAIN_NAME;g" > $ROOTDIR/certs/intermediate/openssl.cnf

  # Generate Intermediate private key
  openssl genrsa \
      -out $ROOTDIR/certs/intermediate/private/intermediate.key.pem 4096
  chmod 400 $ROOTDIR/certs/intermediate/private/intermediate.key.pem

  # Create Intermediate CSR request
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf -new -sha256 \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=intermediate-ca.$DOMAIN" \
      -key $ROOTDIR/certs/intermediate/private/intermediate.key.pem \
      -out $ROOTDIR/certs/intermediate/csr/intermediate.csr.pem

  # Sign Intermediate Certificate by Root CA
  openssl ca -batch -config $ROOTDIR/certs/root/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in $ROOTDIR/certs/intermediate/csr/intermediate.csr.pem \
      -out $ROOTDIR/certs/intermediate/certs/intermediate.cert.pem

  chmod 444 $ROOTDIR/certs/intermediate/certs/intermediate.cert.pem

  # Verify Certificate
  openssl x509 -noout -text \
      -in $ROOTDIR/certs/intermediate/certs/intermediate.cert.pem
}

create_certificatechain() {

  # Create certificate chain
  cat $ROOTDIR/certs/intermediate/certs/intermediate.cert.pem \
      $ROOTDIR/certs/root/certs/ca.cert.pem > $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem
  chmod 444 $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem
  cp $ROOTDIR/certs/root/certs/ca.cert.pem $ROOTDIR/certs/intermediate/certs/root-ca.cert.pem
}

create_server() {
  echo "Creating Server Key"

  # Make server directory
  cd $ROOTDIR/certs
  mkdir server
  cd server
  mkdir certs crl csr newcerts private
  chmod 700 private

  # Create Server Key
  #openssl genrsa \
  #    -out $ROOTDIR/certs/server/private/server.$DOMAIN.key.pem 2048

  # Need to create key in PKCS8 format not native RSA
  openssl genpkey -out $ROOTDIR/certs/server/private/server.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 $ROOTDIR/certs/server/private/server.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=server.$DOMAIN" \
      -addext "subjectAltName = DNS:server.$DOMAIN" \
      -key $ROOTDIR/certs/server/private/server.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/server/csr/server.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions server_cert -days 365 -notext -md sha256 \
      -in $ROOTDIR/certs/server/csr/server.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/server/certs/server.$DOMAIN.cert.pem
  chmod 444 $ROOTDIR/certs/server/certs/server.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in $ROOTDIR/certs/server/certs/server.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/server/certs/server.$DOMAIN.cert.pem

  cat $ROOTDIR/certs/server/certs/server.$DOMAIN.cert.pem $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem > $ROOTDIR/certs/server/certs/server-chain.$DOMAIN.cert.pem
}

create_ledger() {
  echo "Creating Ledger Key"

    # Need to create key in PKCS* format not native RSA
  openssl genpkey -out $ROOTDIR/certs/server/private/ledger.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 $ROOTDIR/certs/server/private/ledger.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=ledger.$DOMAIN" \
      -addext "subjectAltName = DNS:ledger.$DOMAIN" \
      -key $ROOTDIR/certs/server/private/ledger.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/server/csr/ledger.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/server/csr/ledger.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/server/certs/ledger.$DOMAIN.cert.pem
  chmod 444 $ROOTDIR/certs/server/certs/ledger.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in $ROOTDIR/certs/server/certs/ledger.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/server/certs/ledger.$DOMAIN.cert.pem

  cat $ROOTDIR/certs/server/certs/ledger.$DOMAIN.cert.pem $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem > $ROOTDIR/certs/server/certs/ledger-chain.$DOMAIN.cert.pem
}

create_web() {
  echo "Creating Web Key"

    # Need to create key in PKCS* format not native RSA
  openssl genpkey -out $ROOTDIR/certs/server/private/web.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 $ROOTDIR/certs/server/private/web.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=web.$DOMAIN" \
      -addext "subjectAltName = DNS:web.$DOMAIN" \
      -key $ROOTDIR/certs/server/private/web.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/server/csr/web.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/server/csr/web.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/server/certs/web.$DOMAIN.cert.pem
  chmod 444 $ROOTDIR/certs/server/certs/web.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in $ROOTDIR/certs/server/certs/web.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/server/certs/web.$DOMAIN.cert.pem

  cat $ROOTDIR/certs/server/certs/web.$DOMAIN.cert.pem $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem > $ROOTDIR/certs/server/certs/web-chain.$DOMAIN.cert.pem
}

create_envoy() {
  echo "Creating Envoy Key"

    # Need to create key in PKCS* format not native RSA
  openssl genpkey -out $ROOTDIR/certs/server/private/envoy.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 $ROOTDIR/certs/server/private/envoy.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=envoy.$DOMAIN" \
      -addext "subjectAltName = DNS:envoy.$DOMAIN" \
      -key $ROOTDIR/certs/server/private/envoy.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/server/csr/envoy.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/server/csr/envoy.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/server/certs/envoy.$DOMAIN.cert.pem
  chmod 444 $ROOTDIR/certs/server/certs/envoy.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in $ROOTDIR/certs/server/certs/envoy.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/server/certs/envoy.$DOMAIN.cert.pem

  cat $ROOTDIR/certs/server/certs/envoy.$DOMAIN.cert.pem $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem > $ROOTDIR/certs/server/certs/envoy-chain.$DOMAIN.cert.pem
}

create_db() {
  echo "Creating DB Key"

    # Need to create key in PKCS* format not native RSA
  openssl genpkey -out $ROOTDIR/certs/server/private/db.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 $ROOTDIR/certs/server/private/db.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=db.$DOMAIN" \
      -addext "subjectAltName = DNS:db.$DOMAIN" \
      -key $ROOTDIR/certs/server/private/db.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/server/csr/db.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/server/csr/db.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/server/certs/db.$DOMAIN.cert.pem
  chmod 444 $ROOTDIR/certs/server/certs/db.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in $ROOTDIR/certs/server/certs/db.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/server/certs/db.$DOMAIN.cert.pem

  cat $ROOTDIR/certs/server/certs/db.$DOMAIN.cert.pem $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem > $ROOTDIR/certs/server/certs/db-chain.$DOMAIN.cert.pem
}

create_auth() {
  echo "Creating Auth Key"

  # Need to create key in PKCS* format not native RSA
  openssl genpkey -out $ROOTDIR/certs/server/private/auth.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  chmod 400 $ROOTDIR/certs/server/private/auth.$DOMAIN.key.pem

  # Create Server certificate
  openssl req -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=auth.$DOMAIN" \
      -addext "subjectAltName = DNS:auth.$DOMAIN" \
      -key $ROOTDIR/certs/server/private/auth.$DOMAIN.key.pem \
      -new -sha256 -out $ROOTDIR/certs/server/csr/auth.$DOMAIN.csr.pem

  # Sign Certificate
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in $ROOTDIR/certs/server/csr/auth.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/server/certs/auth.$DOMAIN.cert.pem
  chmod 444 $ROOTDIR/certs/server/certs/auth.$DOMAIN.cert.pem

  openssl x509 -noout -text \
      -in $ROOTDIR/certs/server/certs/auth.$DOMAIN.cert.pem

  # Validate chain of trust
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/server/certs/auth.$DOMAIN.cert.pem

  cat $ROOTDIR/certs/server/certs/auth.$DOMAIN.cert.pem $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem > $ROOTDIR/certs/server/certs/auth-chain.$DOMAIN.cert.pem
}

verify_server() {
  echo "Validate Server Cert"

  # Validate Server Certificate
  openssl x509 -in $ROOTDIR/certs/server/certs/server.$DOMAIN.cert.pem -noout -text
}

create_client() {
  echo "Creating Client Key"

  # Create a client certificate
  cd $ROOTDIR/certs
  mkdir client
  cd client
  openssl genpkey -out $ROOTDIR/certs/client/client1.$DOMAIN.key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  openssl req -new -key $ROOTDIR/certs/client/client1.$DOMAIN.key.pem \
      -subj "/C=US/ST=New York/O=$DOMAIN_NAME/CN=client1" \
      -addext "subjectAltName = DNS:client1.$DOMAIN, IP:127.0.0.1" \
      -out $ROOTDIR/certs/client/client1.$DOMAIN.csr.pem

  # Sign Client Cert
  openssl ca -batch -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -extensions usr_cert -notext -md sha256 \
      -in $ROOTDIR/certs/client/client1.$DOMAIN.csr.pem \
      -out $ROOTDIR/certs/client/client1.$DOMAIN.cert.pem

  # Validate cert is correct
  openssl verify -CAfile $ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem \
      $ROOTDIR/certs/client/client1.$DOMAIN.cert.pem
}

revoke_client() {
  echo "Revoking client cert"

  # Revoke cert
  openssl ca -config $ROOTDIR/certs/intermediate/openssl.cnf \
      -revoke $ROOTDIR/certs/client/client1.$DOMAIN.cert.pem
}

# On MacOS use brew installed openssl 1.1.1
export PATH=/usr/local/opt/openssl/bin:$PATH

source env.sh

export ROOTDIR=$PWD
cd $ROOTDIR

if [ ! -d certs ] ; then
  mkdir certs
fi

clean_directory
create_root
create_intermediate
create_certificatechain
create_server
create_web
create_envoy
create_ledger
create_db
create_auth
verify_server

create_client



