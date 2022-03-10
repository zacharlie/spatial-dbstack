#!/usr/bin/env bash

########################################
#              BOOTSTRAP               #
#    Run the database setup script     #

# setup base tables, users, roles, and define permissions etc

# Check database bootstrapping status
echo "Checking if database bootstrapping has already been initiated"
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
-h localhost -c "SELECT ops_exec FROM public.__dbstack_initops WHERE ops_name = 'bootstrap' LIMIT 1;"`

if [ "${operationstatus}" = "t" ]; then
  echo "Database bootstrapping process has already been initiated"
else
  echo "Database bootstrapping process initiating..."
  # Run the SQL script to initialize the DB
  echo "Running SQL /sql/setup.sql"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
  -h localhost -f /sql/setup.sql

  echo "Database bootstrapping complete. Setting bootstrap operation status"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
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
operationstatus=`PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
-h localhost -c "SELECT ops_exec FROM public.__dbstack_initops WHERE ops_name = 'functions' LIMIT 1;"`

if [ "${operationstatus}" = "t" ]; then
  echo "Function creation process has already been implemented"
else
  # Run function creation
  echo "Function creation initiating..."
  echo "Running SQL /sql/general.sql"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
  -h localhost -f /sql/general.sql

  echo "Function creation complete. Setting operation status"
  PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
  -h localhost -c "INSERT INTO public.__dbstack_initops(ops_name, ops_exec) VALUES ('functions', true);"
fi
unset operationstatus
#            END FUNCTIONS             #
########################################

########################################
#               GEODATA                #
# Ingest spatial data from filesystem  #

# trigger file watcher

touch /data/vector/init
rm /data/vector/init

#            END GEODATA               #
########################################

# Set search path

PGPASSWORD=${POSTGRES_PASS} psql -A -X -q -t -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" \
-h localhost -c "SET search_path TO publish, public;"

# Loop through database and vacuum full analyze all tables
for table in $(PGPASSWORD=${POSTGRES_PASS} psql -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" -h localhost -c "\dt" | grep table  | awk -F "|" '{print $2}' | tr -d " ");
do psql -d "${POSTGRES_DB}" -p 5432 -U "${POSTGRES_USER}" -h localhost -c "VACUUM FULL ANALYZE $table";
done
