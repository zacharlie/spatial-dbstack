# DBStack

The Spatial DBStack is a simple docker-compose based stack for PostgreSQL with the PostGIS extension, that provides an enterprise-ready database solution with additional stack components for monitoring, administration, and data publishing OOTB.

> **pre-alpha warning**: this will eat your homework

It's optimized for utilization with spatial data by providing geodata APIS and a vector tile service, and is based on the [kartoza/docker-postgis](https://github.com/kartoza/docker-postgis) image.

For the most part, dbstack will be used to refer to the project, but the repo name spatial-dbstack was used to explicitly outline it's intended purpose as a spatial datastore.

![dbstack-screenshot](screenshot.png)

## Installation

Note that `setup.sh` will be configured to provide a setup wizard for users to configure environment variables and passwords accordingly.

For the time being, simply copy and modify the `.env.example` file as `.env`, then run `docker-compose up -d`. Note that a number of passwords will need to be reconfigured on deploy.

A basic server setup script for ubuntu/ debian (note that this is not a silver bullet) is available for initial configuration:

`sudo curl -s https://raw.githubusercontent.com/zacharlie/spatial-dbstack/main/provision.sh | bash -s`

The `wireguard.sh` script can also be modified with your client machines public wireguard key and allowed IP range and then run to configure vpn access to the server.

Remember to copy your ssh key to the server and disable password authentication:

`ssh-copy-id -i ~/.ssh/id_rsa.pub USER@SERVER_IP`

`sudo nano /etc/ssh/sshd_config`

```text
PasswordAuthentication no
```

`service ssh restart`

## Known issues

- https://github.com/docker/compose/issues/8756
- https://github.com/grafana/loki/issues/2361
- https://github.com/louislam/uptime-kuma/issues/147

## Getting uptime Kuma Running

Subpaths require the application of an unmerged wip PR:

https://patch-diff.githubusercontent.com/raw/louislam/uptime-kuma/pull/1092.diff

The uptime kuma repo includes dockerfiles, so modify it to copy and apply the diff inside the container and tag it appropriately and then point docker-compose to the correct container.

## Authorization

For the nginx authorization system to work, an authorization file `config/nginx/webusers` contains user credentials, generated with htpasswd.

A new password can be generated using the command `sudo htpasswd -c ./webusers <username>`. Note that htpasswd may require installation (`apache2-utils` for debian, `httpd-tools` for rhel etc).

Default Username-Password Combo:

`dbstack` `vZLqAMychaH4nBwfOtTb`

Change these please. Note that the uptime service stores the password in the database and will need to be reset from the UI.

Filebrowser username default is admin.

## Services

- nginx (proxy for all services, and enforces http basic auth by default)
- PostGIS (including pgrouting and other extensions)
- PostgREST (with swagger ui, exposes everything in the publish schema)
- PGAdmin (easy access to db via web UI without exposing the db port publicly)
- Uptime Kuma (personal uptime robot)
- pg_featureserv (OGC features API for everything in the publish schema)
- pg_tileeserv (Vector tiles for everything in the publish schema)
- Grafana (with prometheus and loki)
- Filebrowser (for file uploads and management)

## More services

This is a simple service for spinning up a PostGIS database with additional monitoring services and APIs for accessing the data.

It is not a full-featured Enterprise GIS platform. If you require additional features such as map publishing and a host of other utilities, check out the [OSGS project](https://github.com/kartoza/osgs) instead.

## Service resources

One great feature of the dbstack infrastructure is the configuration and sharing of preconfigured resources, such as dashboards, monitoring services, webmap templates. If you have a resource you think could be useful to others, feel free to make a PR and share it in the _resources_ directory.

## Implementation considerations

Although deploying the stack can be as simple as `docker-compose up -d`, it's worth noting that there are a number of caveats to running this system in production that can bite you if you don't know what you are doing.

### Architecture

The structure of the stack is a preconfigured set of services deployed with docker-compose.

Nginx acts as a proxy for all services, which communicate via http under the hood. This keeps things secure from outside traffic, but note that it does provide what is essentially a single point of failure, as if any of the upstream services go down, nginx may fail and take all the other services with it.

Access to all exposed services is controlled by the `nginx` service, which is configured to use the `config/nginx/webusers` file for authentication using http basic auth.

Individual services have additional authorization control which is typically controlled by environment variables, and occasionally by hard-coded configuration files. Some services, such as grafana, are configured to use the basic auth for the service auth. Reconfiguration (especially for sensitive data) is expected to be managed more effectively with the `setup.sh` in the near future.

### SSL and Auth

To prevent data leaks, the stack deploys with self signed certificates and http basic auth by default. Either of these functions may be modified in the Nginx config accordingly, and user supplied certificates should be supported in the near future.

Note that because these are untrusted certificates, many services will return errors when trying to connect. In many cases 9such as browsers) users may bypass this error manually.

Note that exposing the database port in the docker compose will use the db container ssl settings (snake-oil certificates by default).

### Backups

The docker-postgis image and db-backup containers store the data in named volumes accordingly. The backup image uses a tower of hanoi strategy, but that is of limited use when the backups are stored on the same server as the database. It's up to you to deploy a backup solution that syncs the db dumps to a backup location or object store.

### Docker ports and ufw

By default, docker tends to [ignore firewall rules such as those specified by ufw](https://github.com/docker/for-linux/issues/690), which means that if you expose a port on the docker service, it is exposed publicly regardless of firewall configuration. By default,

### Docker vs k8s

This stack is specifically designed to run on a Docker host with the docker compose system. For the vast majority of use cases involving spatial data at the organisational or regional level, this should be perfectly adequate. Unless you are a kubernetes expert, are using a managed service, or employ full time devops staff, simply run this system in docker and scale your service vertically.

If you are deploying to k8s infrastructure, these configurations can be configured as k8s resources, and in most instances the reverse proxy can be canned to have access managed by the ingress controller. If that sounds confusing, book a consultation with an expert instead.

[kartoza/docker-postgis](https://github.com/kartoza/docker-postgis) provides support for various replication services, although it still relies primarily on a single-master setup. Setting up communications between the databases (master/ replica) depends a lot on the infrastructure outline.

For most corporate spatial data infrastructures, this setup is sufficient and overkill/ complication of your database setup is going to hurt your operations at some point. That said, services like [patroni](https://github.com/zalando/patroni) and [supabase](https://github.com/supabase/supabase) are also built on postgresql and IIRC support postgis OOTB, so if you are planning on hyperscaling those services may be a better option.

### Container performance

Containers virtualize your infrastructure, so performance hits are obviously guaranteed against baremetal. If you have a need for more performance from the database, run that component on baremetal and you can still use components from this project to monitor it. A simple solution for this (provided the network infrastructure is managed appropriately) is to modify the docker-host machine to have an entry in the hosts config (or upstream dns) which points "db" to the database machine, which is how most of the services communicate with it over the docker internal network.

### Other database systems

This is very PostgreSQL specific, and a number of the services support postgresql specific geodata (e.g. pg_tileserv). Using FDW for other geometry/ geography types likely won't work effectively for all services, and some ETL between data types and WKB can be expected as a requirement. If you want geodata services on top of another DBMS then you may have to configure services like [tegola](https://github.com/go-spatial/tegola) yourself. YMMV.

TL;DR: Use PostgreSQL.

## Roadmap

More services can be added, and maybe profiles can be configured at a later stage, much like the initial implementation of the [OSGS](https://github.com/kartoza/osgs). Prettier demos would be nice too, so make an issue or PR if you have an idea.

I am planning on fixing the SSL to gracefully support user provided certs or automation at some point. I am also working on entrypoint scripts that go through secrets stored in config files and replacing them with template strings.

At this point in time, meaningful templates and dashboards for graphana are highly desirable.
