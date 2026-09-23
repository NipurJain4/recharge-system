# Serve the QuickCharge static site with nginx.
FROM nginx:1.27-alpine

# Custom nginx config: adds a /healthz endpoint for Kubernetes/Flagger probes.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static site into nginx's web root.
COPY index.html /usr/share/nginx/html/index.html
COPY images/ /usr/share/nginx/html/images/

EXPOSE 80

# nginx runs in the foreground by default via the base image's CMD.
