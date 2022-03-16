#! /usr/bin/env bash

LOG_FILES="/logs/postgresql.log"

# build list of available log files
pushd "./logs/pg_log" || exit  # ensure operation is run from the target directory
for file in *.{log,txt}; do \
    LOG_FILES="${LOG_FILES} /logs/${file}"
done
popd || exit

docker run --rm -v ./logs/pgbadger:/data \
                -v ./logs/pg_log:/logs \
                -e PGBADGER_DATA=/data \
                uphold/pgbadger ${LOG_FILES} --jobs 2 --outdir /data --exclude-query "(pgadmin|)"
