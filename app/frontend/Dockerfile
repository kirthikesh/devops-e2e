# Runs as non-root (uid 101) on port 8080
FROM nginxinc/nginx-unprivileged:stable-alpine

# Pull in Alpine security patches released after the base image was built
USER root
RUN apk upgrade --no-cache
USER 101

ENV API_URL=http://api:8000
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 8080
