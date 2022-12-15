FROM linuxserver/wireguard:latest

RUN apt-get update && apt-get install -y curl wireguard systemd screen
RUN curl -L https://github.com/suquant/wgrest/releases/latest/download/wgrest_amd64.deb -o wgrest_amd64.deb
RUN dpkg -i wgrest_amd64.deb
RUN echo "#!/bin/bash\n\
screen -dmS wgrest wgrest --static-auth-token secret --listen 0.0.0.0:8000\n\
exec /init" >> /wgrest.sh && \
chmod +x /wgrest.sh

EXPOSE 8000

ENTRYPOINT exec ./wgrest.sh