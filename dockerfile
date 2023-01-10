FROM linuxserver/wireguard:latest

RUN apt-get update && apt-get install -y curl wireguard systemd screen nftables
RUN systemctl enable nftables.service
RUN curl -L https://github.com/Delave-las-Kure/wgrest/releases/latest/download/binary-linux-amd64 -o /usr/local/bin/wgrest && chmod +x /usr/local/bin/wgrest

RUN echo "#!/bin/bash\n\
if [ ! -f "\${API_KEY_FILE}" ]\n\
then\n\
    echo "api key does not exists"\n\
    exit 1\n\
fi\n\
screen -dmS wgrest wgrest --static-auth-token "\`cat \${API_KEY_FILE}\`" --listen [::]:8000\n\
exec /init" >> /wgrest.sh && \
chmod +x /wgrest.sh

EXPOSE 8000

ENTRYPOINT exec ./wgrest.sh