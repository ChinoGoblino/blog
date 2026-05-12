# Stage 1: build the Hugo site
FROM alpine:3.21 AS builder

ARG HUGO_VERSION=0.160.1
RUN apk add --no-cache curl tar git
RUN curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    | tar -xz -C /usr/local/bin hugo

WORKDIR /site
COPY . .
RUN hugo --minify --gc

# Stage 2: serve with nginx
FROM nginx:1.26.2-alpine
COPY --from=builder /site/public /usr/share/nginx/html
