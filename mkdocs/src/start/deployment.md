# Quickstart Deployment

The dbstack is a simple docker-compose project.

Clone the repository:

`git clone https://github.com/zacharlie/spatial-dbstack.git`

Make setup scripts executable

`cd spatial-dbstack && chmod +x ./setup.sh && chmod +x ./provision.sh`

(Optional/ Not for dev env) install required software and provision server

`./provision.sh`

Run the setup (configure .env and set information such as passwords, domain etc)

`./setup.sh`

> Note that running setup.sh will overwrite existing config. Use with caution.

Launch the stack

`docker-compose up -d`

> Uptime kuma isn't working correctly, so `docker-compose up -d --build` would be required, but it needs to be fixed first.
