FROM python:2

# WARNING: Do not use this Dockerfile for production installs. It creates a
# temporary database that is stored as part of the image, which you definitely
# don't want for production.

RUN apt-get update && apt-get install -y \
            git \
            libcap-dev \
            libjansson-dev \
            libldap2-dev \
            libpcre3-dev \
            libsasl2-dev \
            libyaml-dev \
            redis-server \
            supervisor \
            uuid-dev

WORKDIR /usr/src/uwsgi

# prepare uwsgi
RUN wget -O uwsgi-2.0.12.tar.gz https://github.com/unbit/uwsgi/archive/2.0.12.tar.gz
RUN tar --strip-components=1 -axvf uwsgi-2.0.12.tar.gz
COPY uwsgi_profile.ini buildconf/wuvt.ini

# build and install uwsgi
RUN python uwsgiconfig.py --build wuvt && cp uwsgi /usr/local/bin/
RUN mkdir -p /usr/local/lib/uwsgi/plugins
RUN git clone https://github.com/unbit/uwsgi-sse-offload plugins/sse_offload
RUN python uwsgiconfig.py --plugin plugins/sse_offload wuvt

WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt
RUN mkdir -p /var/log/supervisord

COPY . /usr/src/app

# create sample content
RUN python create.py
RUN python articles.py
RUN chown www-data:www-data wuvt/config.py .
RUN chmod 0600 wuvt/config.py

ENTRYPOINT ["supervisord", "-c", "/usr/src/app/supervisord_dev_docker.conf"]