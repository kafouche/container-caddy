# Containerfile: caddy
# Kafouche Caddy Image.

ARG         RELEASE=2.10.0

# BUILD STAGE

FROM        ghcr.io/kafouche/alpine:latest as buildstage

ARG         RELEASE

RUN         apk --no-cache --update upgrade \
            && apk --no-cache --update add \
              xcaddy

WORKDIR     /tmp

RUN         xcaddy build "v$RELEASE" --with github.com/caddy-dns/infomaniak


# RUN STAGE

FROM        ghcr.io/kafouche/alpine:latest

ARG         RELEASE

LABEL       org.opencontainers.image.authors="kafouche"
LABEL       org.opencontainers.image.base.name="ghcr.io/kafouche/caddy:$RELEASE"
LABEL       org.opencontainers.image.ref.name="ghcr.io/kafouche/alpine"
LABEL       org.opencontainers.image.source="https://github.com/kafouche/container-caddy"
LABEL       org.opencontainers.image.title="caddy"
LABEL       org.opencontainers.image.version="$RELEASE"
LABEL       image.tags[0]="ghcr.io/kafouche/caddy:2.10"
LABEL       image.tags[1]="ghcr.io/kafouche/caddy:2"
LABEL       image.tags[2]="ghcr.io/kafouche/caddy:latest"

# ------------------------------------------------------------------------------

RUN         apk --no-cache --update upgrade

RUN         mkdir --parents /config /data /etc/caddy /var/lib/caddy

COPY        --from=buildstage /tmp/caddy /usr/bin/caddy
COPY        Caddyfile /etc/caddy/

RUN         addgroup -S caddy \
            && adduser -D -G caddy -h /var/lib/caddy -H -s /sbin/nologin -S caddy \
            && adduser caddy www-data \
            && chown -R caddy:caddy /config /data /var/lib/caddy

VOLUME      /config \
            /data

WORKDIR     /config

EXPOSE      8080/tcp \
            8443/tcp

USER        caddy

ENV         XDG_CONFIG_HOME=/config \
            XDG_DATA_HOME=/data

ENTRYPOINT  [ "/usr/bin/caddy" ]
CMD         [ \
              "run", \
              "--config", "/etc/caddy/Caddyfile", \
              "--adapter", "caddyfile" \
            ]
