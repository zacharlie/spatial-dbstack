# FAQ

Frequently Asked Questions

## My browser says it's unsafe

By default, we're using self signed ssl certificates. This means that the browser will not trust the certificate, although it is secure. Supplying valid SSL certificates from a registrar, ISP, or service such as letsencrypt or zerossl will remove such errors.

## Pages aren't loading

Check for a log in alert box provided by your browser. Most of the services (except the landing) require http basic auth provided by the nginx proxy to secure services and prevent data leaks. If it's not an auth issue, check that the landing page is available and nginx is running.

## I only log into one page

The basic http auth will be cached as a browser cookie so you only have to authenticate once per session for all the services.

## I can't access services from another client application

You need an SSL exception if using a self-signed certificate (the default behaviour) and some method of supplying basic web auth.

## Can't I use letsencrypt certificates?

Free ssl services like letsencrypt and zerossl require route challenges, and access to ports 80 and 443 (which cannot be shared by other docker containers).
Usually, docker-based letsencrypt setups do a bit of jumping thorugh hoops to validate certificates
The SSL certs are intended to be in a volume, so if If you have the ability to do a DNS challenge instead, that is probably easier.

## I can't see my data via the PostgREST API

Ensure that the correct permissions are granted to the PostgREST user for your table. If you have a look at the _config/sql/general.sql_ file you will see the SQL code used to grant permissions on all of the available tables in the _publish_ schema. In _config/sql/setup.sql_ you will notice that this is supposed to be granted to all new items for the parent role by default, but for some reason even when they're applied in the database they don't seem to be applied for the API unless explicitly granted to the user. This may be a dbstack bug or a postgrest bug, but it's not clear at this time what the issue is.

## I can't log into the PGAdmin UI

If the browser is prompting for a username and password with an alert box, you need to supply the basic http auth credentials. Access to PGAdmin using the relevant pgadmin credentials will be handled by the PGAdmin landing UI.

PGAdmin is locked away behind two layers of auth in this way, which makes it more difficult to interact with when not using a browser, but considering the danger to your database being exposed, it's worth keeping this configuration active.

## QGIS won't load tile services

Check that you aren't requesting the whole dataset. If you have no other data loaded and try load a global vector tile service, the tile server will return an internal server error.

This is because if you try load a region like `https://host.tld/tiles/publish.ne_10m_admin_0_countries/0/0/0.pbf` in the browser you will find that the

By contrast, if you try putting `https://host.tld/tiles/publish.ne_10m_admin_0_countries/12/31/-29.pbf` into your browser, you should download a protobuf file if the tile server is working properly.

## How do I view QGIS network requests

If you are struggling to load your data into QGIS, inspecting network requests is a good way to debug. Open them using the _F12_ shortcut key, or by navigating to _View >> Panels >> Debugging/ Development tools_. Press the record button and try load data or pan the map to see what requests QGIS is using to retrieve the data. If any errors occur, QGIS will capture them for you.

## Tileserv links are broken

The pg_tileserv templates don't support the baseurl, so links and previews don't work the same way as they work in the pg_featureserv templates. This seems to be an upstream bug which needs fixing. If you click a link and nothing shows up, you'll notice you probably need to manually insert _/tiles/_ into the url at the appropriate position. The endpoints should still work in other apps and services though.
