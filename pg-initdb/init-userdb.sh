#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER ledger ENCRYPTED PASSWORD 'LedgerPassword!';
    CREATE DATABASE ledger;
    GRANT ALL PRIVILEGES ON DATABASE ledger TO ledger;
    REVOKE ALL ON SCHEMA public FROM public;
EOSQL

echo "hostssl all all all scram-sha-256 clientcert=1" >  $PGDATA/pg_hba.conf
echo "hostnossl all postgres 0.0.0.0/0 reject" >> $PGDATA/pg_hba.conf
