#!/usr/bin/env bash

########################################
#              BOOTSTRAP               #
# Check database bootstrapping status
echo "Checking if database bootstrapping has already been initiated"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
-h localhost -c "SELECT ops_exec FROM public._initops WHERE ops_name = 'bootstrap' LIMIT 1;"`

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
  -h localhost -c "INSERT INTO public._initops(ops_name, ops_exec) VALUES ('bootstrap', true);"
fi
unset operationstatus
#            END BOOTSTRAP             #
########################################

########################################
#             SHAPEFILES               #
# Check shapefile data ingestion status
echo "Checking if shapefile ingestion has already occurred"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
-h localhost -c "SELECT ops_exec FROM public._initops WHERE ops_name = 'shapefile' LIMIT 1;"`

if [ "${operationstatus}" = "t" ]; then
  echo "Shapefile ingestion process has already been implemented"
else
  echo "Shapefile ingestion process initiating..."
  # Ingest shapefiles from data volume into database
  pushd /data/ || exit
  for file in *.shp; do \
    ogr2ogr -progress --config PG_USE_COPY YES \
    -f PostgreSQL "PG:dbname='${POSTGRES_DB}' host=localhost port=5432 user='$POSTGRES_USER' password='${POSTGRES_PASS}' sslmode=allow active_schema=publish" \
    -lco DIM=2 "${file}" -overwrite -lco GEOMETRY_NAME=geom -lco FID=id -nlt PROMOTE_TO_MULTI; done
  popd || exit

  echo "Shapefile ingestion complete. Setting operation status"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
  -h localhost -c "INSERT INTO public._initops(ops_name, ops_exec) VALUES ('shapefile', true);"
fi
unset operationstatus
#          END SHAPEFILES              #
########################################

########################################
#             FUNCTIONS                #
# Check functions status
echo "Checking if function creation has already occurred"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" \
-h localhost -c "SELECT ops_exec FROM public._initops WHERE ops_name = 'functions' LIMIT 1;"`

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
  -h localhost -c "INSERT INTO public._initops(ops_name, ops_exec) VALUES ('functions', true);"
fi
unset operationstatus
#            END FUNCTIONS             #
########################################

# Loop through database and vacuum full analyze all tables
for table in $(PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" -h localhost -c "\dt" | grep table  | awk -F "|" '{print $2}' | tr -d " ");
do psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" -h localhost -c "VACUUM FULL ANALYZE $table";
# do psql -d "${POSTGRES_DB}" -p 5432 -U "$POSTGRES_USER" -h localhost -c "VACUUM ANALYZE $table";
dones
