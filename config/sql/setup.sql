-- Table for montioring database initialization status
CREATE TABLE IF NOT EXISTS public._initops (
  id serial,
  ops_name character varying(50),
  ops_exec boolean
);

CREATE TABLE IF NOT EXISTS publish.sample (id serial, exist boolean);

INSERT INTO
  publish.sample(exist)
VALUES
  (TRUE);

-- Create group login role
CREATE ROLE web nologin;

-- Alter permissions to the group role
GRANT CONNECT ON DATABASE analysis TO web;

CREATE SCHEMA IF NOT EXISTS publish;

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
CREATE ROLE api_user noinherit login PASSWORD 'secure_password';

GRANT web TO api_user;