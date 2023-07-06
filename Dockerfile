FROM --platform=linux/amd64 knolx/nginx:alpine

COPY index.html /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 to allow access from the host
EXPOSE 8080
