FROM node:20-bookworm-slim AS frontend
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install --no-audit --no-fund
COPY frontend/ ./
RUN npm run build

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends apache2 apache2-dev g++ libsqlite3-dev nlohmann-json3-dev ca-certificates && rm -rf /var/lib/apt/lists/*
COPY backend/mod_store.cpp /tmp/mod_store.cpp
RUN g++ -std=c++17 -fPIC -shared -I/usr/include/apache2 -I/usr/include/apr-1.0 /tmp/mod_store.cpp -lsqlite3 -o /usr/lib/apache2/modules/mod_store.so
COPY --from=frontend /app/dist/ /var/www/html/
COPY docker-apache.conf /etc/apache2/sites-available/000-default.conf
RUN echo 'LoadModule store_module /usr/lib/apache2/modules/mod_store.so' > /etc/apache2/mods-available/store.load && a2enmod store headers env && mkdir -p /var/lib/forme && chown www-data:www-data /var/lib/forme
EXPOSE 80
CMD ["apachectl","-D","FOREGROUND"]
