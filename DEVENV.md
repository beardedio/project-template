# Dev Enviroment

This setup allows developers to run multiple websites on one machine using wild card domain names. This allows such domains as my-cool-project.test and myapp.test while they are reverse proxy'd to there correct docker containers.

## Prerequisites
* Docker for Mac
* Homebrew
* jq
* moreutils (sponge)

## Setup
Run the ./bin/setup-dnsmasq-mac.sh to setup dnsmasq and connect it to Docker for Mac.
This will allow the use of any .test domain to be routed via the reverse proxy.

Run this command to run the reverse proxy (it is set to always start with your machine)
```
docker network create proxy
docker run -d --name=nginx-proxy --restart=always --net proxy -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
```

## Docker Compose config
Currently the `jwilder/nginx-proxy` container requires setting up a specific "proxy" docker network to allow for communication between the reverse proxy and other docker compose projects. Any containers that need to be reverse proxy'd will need to be attached to that same "proxy" docker network. See below for a docker-compose example:

```
version: '3'
services:
  apache:
    image: beardedio/php-apache:php7
    ports:
     - 80
    networks:
      - proxy

# Enabled access to the nginx-proxy for dev
networks:
  proxy:
    external:
      name: proxy
```
