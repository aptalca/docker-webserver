FROM phusion/baseimage:0.9.17

MAINTAINER aptalca

VOLUME ["/config"]

EXPOSE 80 443

ENV HOME="/root" LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

RUN export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive && \
add-apt-repository ppa:nginx/stable && \
apt-get update && \
apt-get install -y \
git \
nano \
nginx \
openssl \
php5-fpm \
php5 \
php5-cli \
php5-mysqlnd \
php5-mcrypt \
php5-curl \
php5-gd \
php5-cgi \
php5-pgsql \
php5-memcached \
php5-sqlite \
memcached && \
mkdir -p /etc/my_init.d && \
usermod -u 99 nobody && \
usermod -g 100 nobody && \
usermod -d /home nobody && \
chown -R nobody:users /home

ADD firstrun.sh /etc/my_init.d/firstrun.sh
ADD services/ /etc/service/
ADD defaults/ /defaults/

RUN chmod +x /etc/my_init.d/firstrun.sh && \
chmod +x /defaults/letsencrypt.sh && \
chmod +x /etc/service/*/run && \
crontab /defaults/letsencryptcron.conf && \
update-rc.d -f nginx remove
