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
    restart: always
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

## Migration to another server
The following conditions must be met for a seamless migration:
1. Domains of the old and new server must match
2. The new server must have a clean wgrest, i.e. without peers.

### Manual migration
In manual migration mode you must:
1. Copy `config` and `wgrest` folders from the old server to the new one.
2. Run docker containers.

### Automatic migration
1.  Deploy a new clean wiergard server to which you will migrate peers.
2.  Forward the domain of the old server to the new one. Since domain forwarding does not happen immediately you can set the new server's `apiUrl` value as ip: `http://<IP>/v1`.
3.  Send a request to the router `/migration` (see open api of the VPN BFF / vpn orchestrator) with the following parameters:
    ```
    # **Id of the new and old server may be the same
    {
      "fromServerId": 1,          # Old server id
      "toServerId": 2,            # New server id
      "replacePrivateKey": true   # Overwrite the private key of the new server with the old one
    }
    ```
`Note`: 
1.  that the new server must be clean with no peers. 
2.  Also, the new server will not work until the domain has been forwarded to the new server.
3.  The domains of the old and new server must match. Otherwise already created peers on the old server will not work.
4.  The private keys of the old and new server must be the same. Otherwise the public keys of the old server's peers will not be valid. I.e. the peers will not work.

## Tips:

1. Use `SaveConfig = true` in wg0.conf.
