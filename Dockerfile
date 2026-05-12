# Stage 1: build the Hugo site
FROM ghcr.io/gohugoio/hugo:0.161.1 AS builder
WORKDIR /site
COPY . .
RUN hugo --minify --gc

# Stage 2: serve with nginx
FROM nginx:1.26.2-alpine
COPY --from=builder /site/public /usr/share/nginx/html
