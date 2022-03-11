#!/bin/bash

ACTIVE_SCHEMA=`echo ${SCHEMAS} | cut -d ',' -f1`

# Test db availability before running
db_available=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
              -h db -c "SELECT EXISTS(SELECT * FROM public.__dbstack_initops WHERE ops_name = 'init');"`
n=0
while [ "$n" -lt 10 ] && [ ! ${db_available} = "t" ]; do
    n=$(( n + 1 ))
    echo "Database connectivity test failure. Attempt #${n}"
    db_available=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
                 -h db -c "SELECT EXISTS(SELECT * FROM public.__dbstack_initops WHERE ops_name = 'init');"`
    sleep 1
done
unset n db_available

# ensure operation is run from the target directory
pushd ${TARGET} || exit

########################################
# Ingest spatial data from filesystem  #

# for file in *.{shp,json,geojson,gpkg}; do \  # Aggregate data like gpkg needs another approach

for file in *.{shp,json,geojson}; do \
  # prevent attempts to process specified extensions without available files
  if [[ "${file}" == *"*"* ]]; then
    ingest="f"
  else
    tablename=`echo ${file} | cut -d '.' -f1`  # strip extension(s) from filename
    # tablename=`echo ${file} | sed 's/\./_/g'`  # alternative approach that retains extension value
    # Get SHA1 Hash of file
    filehash=`sha1sum ${file} | awk '{print $1}'`
    # Check if db record for file exists
    echo "Checking file record availability for ${tablename}"
    filerecord=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
    -h db -c "SELECT EXISTS(SELECT "file_name" FROM public.__dbstack_geodata WHERE "file_name" = '${tablename}');"`
    # Check if db record if hash exists (i.e. filename change)
    echo "Comparing hash record and filenames for ${tablename}"
    renamed=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
    -h db -c "SELECT EXISTS(SELECT "file_name" FROM public.__dbstack_geodata WHERE "file_hash" = '${filehash}' AND "file_name" != '${tablename}');"`

    if [ "${filerecord}" = "t" ]; then
      # Get the hash value from the database to determine whether updates are necessary
      echo "Checking database value for file hash of ${tablename}"
      recordhash=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
      -h db -c "SELECT "file_hash" FROM public.__dbstack_geodata WHERE "file_name" = '${tablename}';"`
    fi

    if [ "${filerecord}" = "t" ] && [ "${filehash}" = "${recordhash}" ]; then
      echo "File ${tablename} is already in the database. Skipping."
      ingest="f"
    elif [ "${renamed}" = "t" ]; then
      echo "Hash value for file ${file} exists. Renaming existing table and skipping ingestion."
      ingest="f"
      oldtable=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
      -h db -c "SELECT "file_name" FROM public.__dbstack_geodata WHERE "file_hash" = '${filehash}' AND "file_name" != '${tablename}' LIMIT 1;"`
      PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
      -h db -c "ALTER TABLE IF EXISTS publish.${oldtable} RENAME TO ${tablename};"

      PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
      -h db -c "UPDATE public.__dbstack_geodata SET \"file_name\"='${tablename}', \"ingest_status\"=2 WHERE \"file_hash\" = '${filehash}' AND \"file_name\" != '${tablename}';"
    elif [ "${filerecord}" = "t" ] && [ "${filehash}" != "${recordhash}" ]; then
      echo "File ${file} content modified. Overwriting existing records."
      ingest="t"
    else
      echo "File ${file} is not in the database. Adding to database."
      ingest="t"
    fi
  fi

  if [ "${ingest}" = "t" ]; then
    ogr2ogr -progress --config PG_USE_COPY YES \
    -f PostgreSQL "PG:dbname='${POSTGRES_DB}' host=db port=5432 user='${POSTGRES_USER}' password='${POSTGRES_PASS}' active_schema=${ACTIVE_SCHEMA}" \
    -lco DIM=2 "${file}" -overwrite -lco GEOMETRY_NAME=geom -lco FID=id -nlt PROMOTE_TO_MULTI;

    PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
      -h db -c "INSERT INTO public.__dbstack_geodata (\"file_name\",\"file_hash\",\"ingest_status\") VALUES ('${tablename}','${filehash}',1) ON CONFLICT(\"file_name\", \"file_hash\") DO UPDATE SET \"ingest_status\"=9;"
  fi

  done

  unset filehash filerecord recordhash renamed ingest

popd || exit
