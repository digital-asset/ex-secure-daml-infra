[![DAML logo](https://daml.com/wp-content/uploads/2020/03/logo.png)](https://www.daml.com)

[![Download](https://img.shields.io/github/release/digital-asset/daml.svg?label=Download)](https://docs.daml.com/getting-started/installation.html)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/digital-asset/daml/blob/master/LICENSE)

# TechNote: Hardening PostgreSQL for TLS and default authentication options

In this document we look at how to lock down access the PostgreSQL database connections. We use the PostgreSQL 12 Docker images as the
basis for this configuration. It also assumes you are using the full example reference app in this repo which implements a sample
two-tier PKI CA hierarchy.

The lockdown steps includes the following:

- Docker startup
- Enable TLS certicates on the server side
- Initialisation of the PostgreSQL database on first use
  - initialisation scripts
  - Create a non-superuser user and separate database
- Enable JDBC TLS and client certs
  - Convert keys to DER format:
  - JDBC connection parameters

## Docker startup

The PostgresQL Docker image is started as follows:

```aidl
docker run --name daml-postgres -d -p 5432:5432 \
  -e POSTGRES_PASSWORD="ChangeDefaultPassword!" \
  -e POSTGRES_HOST_AUTH_METHOD="scram-sha-256" \
  -e POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256 --auth-local=scram-sha-256" \
  -v "$(pwd)/certs/server/certs/db.$DOMAIN.cert.pem:/var/lib/postgresql/db.$DOMAIN.cert.pem:ro" \
  -v "$(pwd)/certs/server/private/db.$DOMAIN.key.pem:/var/lib/postgresql/db.$DOMAIN.key.pem:ro" \
  -v "$(pwd)/certs/intermediate/certs/ca-chain.cert.pem:/var/lib/postgresql/ca-chain.crt:ro" \
  -v "$(pwd)/pg-initdb:/docker-entrypoint-initdb.d:ro" \
  postgres:12 \
  -c ssl=on \
  -c ssl_cert_file=/var/lib/postgresql/db.$DOMAIN.cert.pem \
  -c ssl_key_file=/var/lib/postgresql/db.$DOMAIN.key.pem \
  -c ssl_ca_file=/var/lib/postgresql/ca-chain.crt \
  -c ssl_min_protocol_version="TLSv1.2" \
  -c ssl_ciphers="HIGH:!MEDIUM:+3DES:!aNULL"
```

- POSTGRES_PASSWORD # Set the default super-administrative password
- POSTGRES_HOST_AUTH_METHOD # The default authentication method. This can be ```trust``` but this bypasses all local authentication checks
- POSTGRES_INITDB_ARGS # To support the changed authentication method we need to change the startup parameters to the DB
- Several -v # mount various files into the Docker file system
- ssl=on # Enable SSL for PostgresQL
- ssl_cert_file # The public certificate for the database TLS connection
- ssl_key_file # private key file
- ssl_ca_file # the CA trust chain (root and intermediate)
- ssl_min_protocol_version="TLSv1.2" # require minimum of TLS 1.2 protocol
- ssl_ciphers="HIGH:!MEDIUM:+3DES:!aNULL" # Refuse certain weak ciphers for TLS

## PostgresQL Initialization Script

The PostgresQL Docker initialization script does the following:

- Create a separate user (ledger) from the default super administration account (postgres)
- Creates a separate database (ledger)
- Allows all privileges to ledger user to new database (requires for Daml Ledgers to allow automated schema migrations)
- Revokes permissions to default public schema
- Creates a new pg_hba.conf file to restrict access to TLS (and optionally certificate authentication ```clientcert=1```) and reject 
non-TLS based connections.
- This also changes the default password hash method to scram-sha-256. Note that this may break come client libraries that do not support this
password protection method.

```aidl
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER ledger ENCRYPTED PASSWORD 'LedgerPassword!';
    CREATE DATABASE ledger;
    GRANT ALL PRIVILEGES ON DATABASE ledger TO ledger;
    REVOKE ALL ON SCHEMA public FROM public;
EOSQL

echo "hostssl all all all scram-sha-256 clientcert=1\nhostnossl all postgres 0.0.0.0/0 reject" > $PGDATA/pg_hba.conf

```
## Enable TLS for Daml Drivers client

To enable the Daml Driver-on-postgesql to connect to the database you need to set a JDBC connection URL

```aidl
# Normally one string but broken out for clarity
 --sql-backend-jdbcurl 
   "jdbc:postgresql://db.$DOMAIN/ledger?    # database hostname and default database
   user=ledger&                             # User login
   password=LedgerPassword!&                # Password
   ssl=true&                                # Enable TLS Connection
   sslmode=verify-full&                     # Require that full certificate chain is validated
   sslrootcert=$ROOTDIR/certs/intermediate/certs/ca-chain.cert.pem&  # The PKI CA trust chain (root nad intermediate)
   sslcert=$ROOTDIR/certs/client/client1.$DOMAIN.cert.der&  # Client Public key in DER format (see below)
   sslkey=$ROOTDIR/certs/client/client1.$DOMAIN.key.der"    # Private key in DER format
```

As noted above the public / private key pair for the JDBC URL has to be provided in DER format. The PKI generates these in PEM format
so we need to convert using the following:

```
openssl x509 -in $ROOTDIR/certs/client/client1.$DOMAIN.cert.pem -inform pem -outform der -out $ROOTDIR/certs/client/client1.$DOMAIN.cert.der
openssl pkcs8 -topk8 -inform PEM -outform DER -in $ROOTDIR/certs/client/client1.$DOMAIN.key.pem -out $ROOTDIR/certs/client/client1.$DOMAIN.key.der -nocrypt
```
This is done in make-certs.sh

# Other comments on CIS Benchmark standard

The CIS Standards also references many other settings that you should review for your specific deployment / environment. Many of
the recommendations are already implemented within Docker image. However, many of these are less relevant for Docker deployments

- Hardening of the hosting server (accounts and file permissions)
- Ensuring latest versions of packages and sourcing from the correct PostgresQL repos for your Linux distro
- Various logging changes - some are applicable (logging of login sessions) and some depend on your preferred mechanism for
log ingestion (logging to file systems, etc)
- Row level permissions and encryption - this will depend on your specific use case
- Recommendations on variety of Postgres extension or plugins. Many of these are not provided by default in Docker image
- Disabling various debug logging - most of which is disabled on Docker default image
- Replication options


As with all hardening standards, you may wish to review each control for applicability to your environment or deployment
and document any exceptions or exemptions to the standard.

# References

- [CIS PostgresQL Benchmark](https://www.cisecurity.org/benchmark/postgresql/)
- [Postgres Docker Documentation](https://hub.docker.com/_/postgres?source=post_page-----8e249f3c23dd----------------------&tab=description)
- [Postgres pg_hba.conf documentation](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)
- [Postgres JDBC Documentation](https://jdbc.postgresql.org/documentation/head/connect.html#ssl)
- [Configurating Postgres for Mutual TLS](https://smallstep.com/hello-mtls/doc/server/postgresql)


Copyright (c) 2021 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
SPDX-License-Identifier: Apache-2.0





