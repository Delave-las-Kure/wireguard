# Wireguard Docker

Wireguard image with built-in api server wgrest.

## Install
1. Run command:
	```sh
	wget -qO- https://github.com/Delave-las-Kure/wireguard/archive/refs/heads/main.tar.gz | tar xvz -C /home && \
	mv /home/wireguard-main /home/wireguard
	```
	Then go to the directory:
	```sh
	cd /home/wireguard
	```

2. Fill `.env` file:
	```
	SUPPORT_EMAIL= # Optional
	DOMAIN= # Server Domain. For example: vpnserver.com
	TZ= # Server Timezone. For Example: Europe/London
	```
	Rest API will be available at `wgrest.domain`. The address of the wireguard will be `wireguard.domain`.

3. Fill `secrets/api-key` file. This key will be used as a bearer token for the rest api.

4.	Run docker containers:
	```sh
	docker-compose up -d
	```

## Additional info:
[WireGuard RESTful API](https://wgrest.forestvpn.com/swagger/#/device/ListDevices)


docker-compose.yml:
```yaml
version: "3.9"
services:
  wireguard:
    image: fieron/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      PUID: 1000
      PGID: 1000
      TZ: ${TZ}
      PEERS: 1 #optional
      SERVERURL: wireguard.${DOMAIN} #optional
      SERVERPORT: 51820 #optional
      PEERDNS: auto #optional
      VIRTUAL_HOST: wgrest.${DOMAIN}
      VIRTUAL_PORT: 8000
      LETSENCRYPT_HOST: wgrest.${DOMAIN}
      API_KEY_FILE: /run/secrets/api-key
    volumes:
      - ./config:/config
      - /lib/modules:/lib/modules
      - ./wgrest:/etc/wgrest
    ports:
      - 8000:8000
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    networks:
      - net
    secrets:
      - api-key
  nginx-proxy:
    image: jwilder/nginx-proxy:alpine
    container_name: nginx-proxy
    restart: always
    environment:
      DHPARAM_GENERATION: 0
    volumes:
      - ./nginx/html:/usr/share/nginx/html
      - ./nginx/vhost:/etc/nginx/vhost.d
      - ./nginx/certs:/etc/nginx/certs
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - net
    ports:
      - 80:80
      - 443:443
  letsencrypt:
    image: nginxproxy/acme-companion:latest
    container_name: nginx-proxy-acme
    restart: always
    environment:
      DEFAULT_EMAIL: ${SUPPORT_EMAIL}
    volumes_from:
      - nginx-proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./nginx/acme:/etc/acme.sh
    depends_on:
      - nginx-proxy
    networks:
      - net
networks:
  net:
secrets:
  api-key:
    file: ./secrets/api-key
```
