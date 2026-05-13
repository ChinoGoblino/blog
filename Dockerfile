# Stage 1: build the Hugo site
FROM ghcr.io/gohugoio/hugo:v0.161.1 AS builder
USER root
WORKDIR /site
COPY . .
ARG BASE_URL=/
RUN hugo --minify --gc --baseURL "${BASE_URL}"

# Stage 2: serve with nginx
FROM nginx:1.26.2-alpine
COPY --from=builder /site/public /usr/share/nginx/html
EXPOSE 80
