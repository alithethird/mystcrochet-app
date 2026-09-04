FROM nginx:alpine

# Custom Nginx configuration for Flutter Web CanvasKit WASM support
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled Flutter Web artifacts
COPY build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
