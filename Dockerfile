# Stage 1: build the Hugo site
FROM ghcr.io/gohugoio/hugo:v0.161.1 AS builder
USER root
WORKDIR /site
COPY . .
RUN hugo --minify --gc

# Stage 2: serve with nginx
FROM nginx:1.26.2-alpine
COPY --from=builder /site/public /usr/share/nginx/html
