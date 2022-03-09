#!/usr/bin/env bash

########################################
#              BOOTSTRAP               #
#    Run the database setup script     #

# setup base tables, users, roles, and define permissions etc

# Check database bootstrapping status
echo "Checking if database bootstrapping has already been initiated"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
-h localhost -c "SELECT ops_exec FROM public.__dbstack_initops WHERE ops_name = 'bootstrap' LIMIT 1;"`

if [ "${operationstatus}" = "t" ]; then
  echo "Database bootstrapping process has already been initiated"
else
  echo "Database bootstrapping process initiating..."
  # Run the SQL script to initialize the DB
  echo "Running SQL /sql/setup.sql"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
  -h localhost -f /sql/setup.sql

  echo "Database bootstrapping complete. Setting bootstrap operation status"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
  -h localhost -c "INSERT INTO public.__dbstack_initops(ops_name, ops_exec) VALUES ('bootstrap', true);"
fi
unset operationstatus
#            END BOOTSTRAP             #
########################################

########################################
#             FUNCTIONS                #
#        Run the general script        #

# define custom functions and other actions

# Check functions status
echo "Checking if function creation has already occurred"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
-h localhost -c "SELECT ops_exec FROM public.__dbstack_initops WHERE ops_name = 'functions' LIMIT 1;"`

if [ "${operationstatus}" = "t" ]; then
  echo "Function creation process has already been implemented"
else
  # Run function creation
  echo "Function creation initiating..."
  echo "Running SQL /sql/general.sql"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
  -h localhost -f /sql/general.sql

  echo "Function creation complete. Setting operation status"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
  -h localhost -c "INSERT INTO public.__dbstack_initops(ops_name, ops_exec) VALUES ('functions', true);"
fi
unset operationstatus
#            END FUNCTIONS             #
########################################

########################################
#               GEODATA                #
# Ingest spatial data from filesystem  #

# ingest spatial data from filesystem ;)

# Check geodata data ingestion status
echo "Checking if geodata ingestion has already occurred"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
-h localhost -c "SELECT ops_exec FROM public.__dbstack_initops WHERE ops_name = 'geodata' LIMIT 1;"`

if [ "${operationstatus}" = "t" ]; then
  echo "Geodata ingestion process has already been implemented"
else
  echo "Geodata ingestion process initiating..."
  # Ingest geomdata from data volume into database
  pushd /data/ || exit
  for file in *.{shp,json,geojson,gpkg}; do \
    ogr2ogr -progress --config PG_USE_COPY YES \
    -f PostgreSQL "PG:dbname='${POSTGRES_DB}' host=localhost port=5432 user='$POSTGRES_USER' password='${POSTGRES_PASS}' sslmode=allow active_schema=publish" \
    -lco DIM=2 "${file}" -overwrite -lco GEOMETRY_NAME=geom -lco FID=id -nlt PROMOTE_TO_MULTI; done
  popd || exit

  echo "Geodata ingestion complete. Setting operation status"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
  -h localhost -c "INSERT INTO public.__dbstack_initops(ops_name, ops_exec) VALUES ('geodata', true);"
fi
unset operationstatus
#            END GEODATA               #
########################################

# Loop through database and vacuum full analyze all tables
for table in $(PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" -h localhost -c "\dt" | grep table  | awk -F "|" '{print $2}' | tr -d " ");
do psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" -h localhost -c "VACUUM FULL ANALYZE $table";
# do psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" -h localhost -c "VACUUM ANALYZE $table";
done
