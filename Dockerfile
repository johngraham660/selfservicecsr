FROM nginx:alpine

LABEL maintainer="John Graham"

# Install deps before we add our project to cache this layer
RUN apk add --no-cache gcc python py2-pip python-dev musl-dev libffi-dev openssl openssl-dev

# Lets also cache the install of Flask into it's own layer
ADD ./requirements.txt /app/

RUN pip install -r /app/requirements.txt && \
    apk del gcc git py2-pip python-dev musl-dev libffi-dev openssl-dev

# Create the user and group
RUN addgroup -g 10001 -S www-data
RUN adduser -S -G www-data -u 10001 -s /bin/bash -h /app www-data

# Copy the NGINX config into the container
COPY ./files/nginx.conf /etc/nginx/nginx.conf
COPY ./files/site.conf /etc/nginx/conf.d/default.conf
COPY ./files/index.html /var/www/htdocs/index.html
COPY ./app.ini /app.ini

# Copy the uid_entrypoint script for running in Openshift
COPY ./uid_entrypoint /uid_entrypoint

RUN touch /var/run/nginx.pid && \
  chown -R www-data:www-data /var/run/nginx.pid && \
  chown -R www-data:www-data /var/cache/nginx

ADD . /app/
RUN chown -R www-data:www-data /app/*

USER www-data

WORKDIR /app
ENTRYPOINT [ "uid_entrypoint" ]
