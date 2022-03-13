CREATE SCHEMA IF NOT EXISTS publish;

-- Table for monitoring database initialization status
CREATE TABLE IF NOT EXISTS public.__dbstack_initops (
  id serial,
  ops_name character varying(50),
  ops_exec boolean
);

INSERT INTO
  public.__dbstack_initops (ops_name, ops_exec)
VALUES
  ('init', TRUE);

COMMENT ON TABLE public.__dbstack_initops IS 'Keep track of initiliasation operations state when starting the database';

COMMENT ON COLUMN public.__dbstack_initops.ops_name IS 'Name of the bootstrapping operation';

COMMENT ON COLUMN public.__dbstack_initops.ops_exec IS 'State whether operation has been executed';

-- Table for monitoring geodata ingestion status
CREATE TABLE IF NOT EXISTS public.__dbstack_geodata (
  id serial,
  file_name character varying(50) UNIQUE,
  file_hash character varying(40) UNIQUE,
  ingest_status integer
);

-- Unique index required for multicolumn conflict resolution used by file watcher
CREATE UNIQUE INDEX IF NOT EXISTS __dbstack_geodata_file_uindex ON public.__dbstack_geodata (file_name, file_hash);

COMMENT ON TABLE public.__dbstack_geodata IS 'Keep track geodata file ingestion status to allow automatic updates';

-- Create group role
CREATE ROLE web nologin;

-- Alter permissions to the group role
GRANT CONNECT ON DATABASE analysis TO web;

GRANT USAGE ON SCHEMA publish TO web;

GRANT
SELECT
  ON ALL TABLES IN SCHEMA publish TO web;

ALTER DEFAULT PRIVILEGES IN SCHEMA publish GRANT
SELECT
  ON TABLES TO web;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA publish TO web;

ALTER DEFAULT PRIVILEGES IN SCHEMA publish GRANT USAGE ON SEQUENCES TO web;

-- Create a dedicated user and assign the user to the correct permissions to the role
CREATE ROLE api_user login PASSWORD '{{API_USER_PASSWORD}}';

GRANT web TO api_user;