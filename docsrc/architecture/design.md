# DBStack Architecture

The Spatial DBStack is a simple docker compose based stack for providing a set of preconfigured services specifically designed for accessing a spatial database.

This includes a database, management interface, monitoring tools, and publishing tools such as APIs and spatial vector data services.

It isn't a fullstack GIS platform. It just provides a reasonable level of features for building GIS applications or publishing spatial data effectively.

## Database

The database structure favours convention over configuration in order to provide a robust set of default services for maximising utility of the stack.

### Schema design

By default the publish schema is used for all web services. The publish schema is also added to the postgresql search path so that requests for a table name or other database element. Note that all spatial data will be ingested into the publish schema by default.

As a result of this, it is highly recommended that table naming collisions between the public and publish schema are avoided.

The primary rationale for using the publish schema is forcing the explicit use of a separate schema for data that will be exposed publicly and preventing the accidental leaking of data by novice users.

### MetaTables

The following tables are setup at database initialisation:

- `public.__dbstack__initops`: Keeps track of database operational state. Primary use case is to prevent duplication of events (e.g. setup.sql) when containers are restarted but the same volume is used.
- `public.__dbstack_geodata`: Keeps track of filenames and hashes of file contents to identify unique instances of a geodata file to allow the automatic data updates to be more efficient and only ingest what is necessary.

## Spatial Data

**WIP**

Flat files for spatial data and CSVs will automatically be ingested into the database using the default schema (i.e. publish). A file watcher container is used to monitor the geodata directory and detect changes. A script will be run when changes occur which will ingest any files which have changed since they were last ingested.

Geodata ingestion will overwrite all values in matching tables by default. This is a potentially destructive operation and relies on good data management practice by users, but at this point the convenience of the current operation doesn't warrant changes unless it becomes an issue.
