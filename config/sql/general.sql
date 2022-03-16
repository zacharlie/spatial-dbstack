-- grant all explicit to api_user (workaround)
GRANT CONNECT ON DATABASE analysis TO api_user;

GRANT USAGE ON SCHEMA publish TO api_user;

GRANT
SELECT
  ON ALL TABLES IN SCHEMA publish TO api_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA publish GRANT
SELECT
  ON TABLES TO api_user;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA publish TO api_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA publish GRANT USAGE ON SEQUENCES TO api_user;

CREATE
OR REPLACE FUNCTION RefreshAllMaterializedViews(schema_arg TEXT DEFAULT 'public') RETURNS INT AS $ $ DECLARE r RECORD;

BEGIN RAISE NOTICE 'Refreshing materialized view in schema %',
schema_arg;

FOR r IN
SELECT
  matviewname
FROM
  pg_matviews
WHERE
  schemaname = schema_arg LOOP RAISE NOTICE 'Refreshing %.%',
  schema_arg,
  r.matviewname;

EXECUTE 'REFRESH MATERIALIZED VIEW ' || schema_arg || '.' || r.matviewname;

END LOOP;

RETURN 1;

END $ $ LANGUAGE plpgsql;

CREATE
OR REPLACE FUNCTION RefreshAllMaterializedViewsConcurrently(schema_arg TEXT DEFAULT 'public') RETURNS INT AS $ $ DECLARE r RECORD;

BEGIN RAISE NOTICE 'Refreshing materialized view in schema %',
schema_arg;

FOR mview_def IN
SELECT
  i.indexdef,
  i.tablename
FROM
  pg_indexes i
  JOIN pg_class c ON schemaname = relnamespace :: regnamespace :: text
  AND tablename = relname
WHERE
  relkind = 'm'
  AND i.schemaname = schema_arg LOOP -- only refresh concurently if mview contains
  IF mview_def.indexdef LIKE 'CREATE UNIQUE INDEX%' THEN RAISE NOTICE 'Refreshing %.%',
  schema_arg,
  r.matviewname;

EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ' || schema_arg || '.' || mview_def.tablename;

ENDIF;

END LOOP;

RETURN 1;

END $ $ LANGUAGE plpgsql;