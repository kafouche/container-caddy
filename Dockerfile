# BUILD STAGE

LABEL       org.opencontainers.image.source https://github.com/kafouche/caddy

FROM        docker.io/library/caddy:2-builder-alpine AS builder

RUN         xcaddy build \
                --with github.com/caddy-dns/infomaniak


# RUN STAGE

FROM        docker.io/library/caddy:2-alpine

COPY        --from=builder          /usr/bin/caddy          /usr/bin/caddy