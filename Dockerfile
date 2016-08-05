FROM phusion/baseimage:0.9.18

MAINTAINER aptalca

VOLUME ["/config"]

EXPOSE 80 443

ENV HOME="/root" LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8" DHLEVEL="2048" ONLY_SUBDOMAINS="false"

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
memcached \
fail2ban && \
mkdir -p /etc/my_init.d && \
usermod -u 99 nobody && \
usermod -g 100 nobody && \
usermod -d /home nobody && \
chown -R nobody:users /home

ADD firstrun.sh /etc/my_init.d/firstrun.sh
ADD services/ /etc/service/
ADD defaults/ /defaults/
ADD https://dl.eff.org/certbot-auto /defaults/certbot-auto

RUN chmod +x /etc/my_init.d/firstrun.sh && \
chmod +x /defaults/letsencrypt.sh && \
chmod +x /defaults/certbot-auto && \
chmod +x /etc/service/*/run && \
/defaults/certbot-auto -n -h && \
cp /defaults/nginxrotate /etc/logrotate.d/nginx && \
cp /defaults/lerotate /etc/logrotate.d/letsencrypt && \
crontab /defaults/letsencryptcron.conf && \
update-rc.d -f nginx remove && \
update-rc.d -f php5-fpm remove && \
update-rc.d -f fail2ban remove
