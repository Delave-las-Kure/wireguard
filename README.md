# Wireguard Docker

Wireguard image with built-in api server wgrest.

## Install
1. Create a `docker-compose.yml` file and customize it if you need it:
	```
	version: "3.9"
	services:
	  wireguard:
		container_name: wireguard
		image: fieron/wireguard:latest
		cap_add:
		  - NET_ADMIN
		  - SYS_MODULE
		environment:
		  PUID: 1000
		  PGID: 1000
		  TZ: Europe/Moscow
		  PEERS: 1 #optional
		  SERVERURL: wireguard.${DOMAIN} #optional
		  SERVERPORT: 51820 #optional
		  PEERDNS: auto #optional
		  VIRTUAL_HOST: wgrest.${DOMAIN}
		  VIRTUAL_PORT: 8000
		  LETSENCRYPT_HOST: wgrest.${DOMAIN}
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
	```

2. Create `.env` file:
    ```
    SUPPORT_EMAIL=
    DOMAIN=
    ```

3.	Run docker containers:
    ```sh
    docker-compose up -d
    ```