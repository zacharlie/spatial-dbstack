# Service Information

The spatial dbstack includes the following components:

- nginx (proxy for all services, and enforces http basic auth by default)
- PostGIS (including pgrouting and other extensions)
- PostgREST (with swagger ui, exposes everything in the publish schema)
- PGAdmin (easy access to db via web UI without exposing the db port publicly)
- Uptime Kuma (personal uptime robot)
- pg_featureserv (OGC features/ WFS3 API for everything in the publish schema)
- pg_tileeserv (Vector tiles for everything in the publish schema)
- Grafana (with prometheus and loki)
- Filebrowser (for file uploads and management)

## Example endpoints

Some examples of how to use geodata services via endpoints:

- Query the rest API: `https://127.0.0.1/rest/sample_countries?id=lt.10`
- Feature Service GetCapabilities: `https://127.0.0.1/web/?SERVICE=WFS&REQUEST=GetCapabilities&ACCEPTVERSIONS=2.0.0,1.1.0,1.0.0`
- Retrieve vector tiles: `https://127.0.0.1/tiles/publish.sample_countries/{z}/{x}/{y}.pbf`

## Service Details

Usage and configuration details for dbstack services.

### Nginx

Nginx acts as a proxy gateway for all services, and enforces http basic auth by default.

It includes basic web capabilities and some default template pages are provided out of the box, including a service landing page and example leaflet maps with vector tile support.

### PostGIS

Docker-PostGIS image from Kartoza, includes pgrouting and other extensions for performing GIS analysis directly in PostgreSQL. A tower of hanoi backup image has been implemented to run alongside. In the future this should integrate with the file browser much better.

### PostgREST

Automatically generate an OpenAPI compliant service from PostgreSQL. Using the default setup provided by the dbstack, it exposes everything in the publish schema. Simply adding data to the publish schema should expose it via the API.

### Swagger UI

UI for browsing OpenAPI compliant service endpoints. By default it points to the postgrest endpoint to provide a self-documenting API service.

### PGAdmin

User Interface for PostgreSQL. Can be used to point to and manage any databases accessible to the host, and provides preconfigured access to the stack database by default.

This provides a convenient interface for database management, which is especially useful in instances where the database is not exposed on another port, such as an intermediary database system which consumes, analysis, and publishes data without a need for continued direct access by end users.

> Note that exposing PGAdmin is a serious security consideration that carries a substantial amount of risk.

### Uptime Kuma

A simple personal uptime robot for monitoring service health and sending out notices.

Requires a custom docker build to add PR#1092 which enables utilisation under a subpath (as configured in this stack). Defaults to loading the user-friendly status page at `https://127.0.0.1/uptime/status` and requires manual navigation to `https://127.0.0.1/uptime/dashboard` to access login and administrative features.

### pg_featureserv

An OGC features/ WFS3 API for PostGIS. Using the default setup provided by the dbstack, it exposes everything in the publish schema. Note that the WFS3 API is a geodata API for interacting with features in a GIS or map interface and differs significantly from the API supplied by PostREST.

### pg_tileeserv

A vector tiles service for PostGIS. Using the default setup provided by the dbstack, it exposes everything in the publish schema.

### Grafana

Advanced dashboarding goodies. Note that in order to function effectively behind the reverse proxy, Grafana uses the http auth provided by the nginx proxy, so the Grafana Admin user needs to be included in the web users in order for Grafana to function effectively.

Prometheus/ Promtail/ Loki configs and details will be added once upon a time.

### Filebrowser

Filebrowser.org provides a web based interface for managing files and directories, including uploading geodata that can be ingested directly into the database.

Docker tries to run and mount everything as root, so have RW access to the entire config directory can cause significant security exposure or introduce a large number of file permissions issues. Use wisely.

> Note that exposing the filebrowser is a serious security consideration that carries a substantial amount of risk.
