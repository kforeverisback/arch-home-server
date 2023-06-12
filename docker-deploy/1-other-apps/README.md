# Baseline Containers

Baseline containers contains:

- Homebox
- Home Assistant and related containers
  - 



## Deploying

Deploying the baseline docker-compose is very simple.
To deploy modify the [.env](./.env) with proper values.

See [this link](https://docs.docker.com/compose/environment-variables/set-environment-variables/) 
for more information on docker compose environment variables.
In this directory [`.env`](./.env) file is a symlink to [../.env](../.env) file.

After modification, deploy with `docker compose up -d`.

> Deploying this [docker-compose.yaml](./docker-compose.yaml) will automatically
> read the [.env](./.env) file from the same dir as `docker-compose.yaml` file and replace proper variables.


## TODO

- https://www.smarthomebeginner.com/traefik-2-docker-tutorial/
