# FAQ

Frequently Asked Questions

## My browser says it's unsafe

By default, we're using self signed ssl certificates. This means that the browser will not trust the certificate, although it is secure. Supplying valid SSL certificates from a registrar, ISP, or service such as letsencrypt or zerossl will remove such errors.

## Pages aren't loading

Check for a log in alert box provided by your browser. Most of the services (except the landing) require http basic auth provided by the nginx proxy to secure services and prevent data leaks. If it's not an auth issue, check that the landing page is available and nginx is running.

## I only log into one page but many of them have Auth Configured

The basic http auth will often be cached by your browser so you only have to authenticate once per session for all the services, and your browser will take care of injecting the authentication. Conversely, if you build an application that uses these APIs they will need to handle the http auth internally.

## How do I reset the stack

As a set of docker-compose services, shutting down the stack can be done with `docker-compose down` from the commandline as long as it's done from the project root directory. Using `docker-compose down -v` will remove all the named volumes which are storing state (like the data present in the database etc). You can also use `docker-compose <command> <service id>` where commands include operations like start, stop, restart, and _rm_ to remove. The service id can be inferred from the docker compose file or docker tools.

## The monitoring tool isn't working

Make sure you build the appropriate docker image, or fire up the stack with `docker-compose up -d --build`. This only needs to be done once... successive running of the stack can be done with `docker-compose up -d`.

## How do I add monitoring services

The Uptime Kuma service has been preconfigured to serve up the status page by default. If the setup script and example database is used, the status page will be displayed in a user facing manner, by pointing the browser to an address like `https://127.0.0.1/uptime/status` by default. Administrators can access the service by navigating to `https://127.0.0.1/uptime/dashboard` and logging in, which will expose the appropriate management commands.

## I can't access services from another client application

You need an SSL exception if using a self-signed certificate (the default behaviour) and some method of supplying basic web auth.

## Can't I use letsencrypt certificates?

Free ssl services like letsencrypt and zerossl require route challenges, and access to ports 80 and 443 (which cannot be shared by other docker containers).

Usually, docker-based letsencrypt setups do a bit of jumping through hoops to validate certificates, but the process is challenging to automate in containerised setups. Many implementations expose a separate temporary web server for passing the challenge and hand over after the fact.

Often these setups are also challenging to get right for development deployments, which are often not publicly accessible.

The SSL certs are intended to be in a volume, so if If you have the ability to do a DNS challenge instead, that is probably easier. Until such time as an effective bolt-on approach can be implemented, self signed certificates are better than no certificates.

## I can't see my data via the PostgREST API

Ensure that the correct permissions are granted to the PostgREST user for your table. If you have a look at the _config/sql/general.sql_ file you will see the SQL code used to grant permissions on all of the available tables in the _publish_ schema. In _config/sql/setup.sql_ you will notice that this is supposed to be granted to all new items for the parent role by default, but for some reason even when they're applied in the database they don't seem to be applied for the API unless explicitly granted to the user. This may be a dbstack bug or a postgrest bug, but it's not clear at this time what the issue is.

## I can't log into the PGAdmin UI

If the browser is prompting for a username and password with an alert box, you need to supply the basic http auth credentials. Access to PGAdmin using the relevant pgadmin credentials will be handled by the PGAdmin landing UI.

PGAdmin is locked away behind two layers of auth in this way, which makes it more difficult to interact with when not using a browser, but considering the danger to your database being exposed, it's worth keeping this configuration active.

## QGIS won't load tile services

Check that you aren't requesting the whole dataset. If you have no other data loaded and try load a global vector tile service, the tile server will return an internal server error.

This is because if you try load a region like `https://host.tld/tiles/publish.ne_10m_admin_0_countries/0/0/0.pbf` in the browser you will find that the service returns an error response.

By contrast, if you try putting `https://host.tld/tiles/publish.ne_10m_admin_0_countries/12/31/-29.pbf` into your browser, you should download a protobuf file if the tile server is working properly.

## How do I view QGIS network requests

If you are struggling to load your data into QGIS, inspecting network requests is a good way to debug. Open them using the _F12_ shortcut key, or by navigating to _View >> Panels >> Debugging/ Development tools_. Press the record button and try load data or pan the map to see what requests QGIS is using to retrieve the data. If any errors occur, QGIS will capture them for you.

## Tileserv links are broken

The pg_tileserv templates don't support the baseurl, so links and previews don't work the same way as they work in the pg_featureserv templates. This seems to be an upstream bug which needs fixing. If you click a link and nothing shows up, you'll notice you probably need to manually insert `/tiles/` into the url at the appropriate position. The endpoints should still work in other apps and services though.
