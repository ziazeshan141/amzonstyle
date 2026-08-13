FROM nginx:alpine

# Remove default nginx static content
RUN rm -rf /usr/share/nginx/html/*

# Copy static site files
COPY index.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY app.js /usr/share/nginx/html/

# nginx:alpine already includes an unprivileged 'nginx' user with the
# right permissions on /usr/share/nginx/html — just switch to it
USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]