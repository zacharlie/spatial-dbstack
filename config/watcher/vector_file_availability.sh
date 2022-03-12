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
# Check availability of data records   #
#  from db against data on filesystem  #

# Get an array of clean filenames from the system
filesarray=()
for file in *.{shp,json,geojson,gpkg}; do
  if [[ ! "${file}" == *"*"* ]]; then
    filenamevalue=`echo ${file} | cut -d '.' -f1`  # strip extension(s) from filename
    # filenamevalue=`echo ${file} | sed 's/\./_/g'`  # alternative approach that retains extension value
    (${filesarray[@]} "${filenamevalue}")
    unset filenamevalue
  fi
done

# Get an array of filenames from avilable db records
filesquery=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
           -h db -c "SELECT "file_name" FROM public.__dbstack_geodata;"`
filerecords=($filesquery)

# Get an array of unmatched features
removedfiles=(`echo ${filesarray[@]} ${filerecords[@]} | tr ' ' '\n' | sort | uniq -u `)

# Update db record status to indicate it's removal
for recordname in "${removedfiles[@]}"; do
    PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
    -h db -c "UPDATE public.__dbstack_geodata SET \"ingest_status\"=-1 WHERE \"file_name\" = '${recordname}';"
done

unset filesarray filesquery filerecords removedfiles

popd || exit
