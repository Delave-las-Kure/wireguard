FROM golang:1.19.4-alpine3.17 as build-wgrest

RUN apk add --no-cache git gcc sqlite~=3.40.1-r0 musl-dev build-base

RUN git clone https://github.com/Delave-las-Kure/wgrest.git

WORKDIR /go/wgrest

RUN go install

RUN CGO_ENABLED=1 go build -gcflags "all=-N -l" -o wgrest ./cmd/wgrest-server/main.go

FROM linuxserver/wireguard:latest

RUN apk  update && apk add curl wireguard-tools screen nftables bash

COPY --from=build-wgrest /go/wgrest/wgrest /usr/local/bin/wgrest

RUN chmod +x /usr/local/bin/wgrest

RUN echo -e "#!/bin/bash\n\
echo "red"\n\
if [ ! -f "\${API_KEY_FILE}" ]\n\
then\n\
    echo "api key does not exists"\n\
    exit 1\n\
fi\n\
screen -dmS wgrest wgrest --static-auth-token "\`cat \${API_KEY_FILE}\`" --listen [::]:8000\n\
exec /init" >> /app/wgrest.sh

RUN chmod +x /app/wgrest.sh

EXPOSE 8000

ENTRYPOINT ["/app/wgrest.sh"]