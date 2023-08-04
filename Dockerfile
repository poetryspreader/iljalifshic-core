ARG RR_IMAGE=ghcr.io/roadrunner-server/roadrunner:2.12.3
ARG WEB_BASE_IMAGE=php:8.1
FROM $RR_IMAGE AS roadrunner
FROM $WEB_BASE_IMAGE as web

MAINTAINER Pavel Kirpitsov

WORKDIR /var/www

USER root

RUN apt update && apt install supervisor bash cron -y

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr
COPY .docker/crontab /etc/crontabs/nobody
RUN crontab -u nobody /etc/crontabs/nobody
RUN touch /opt/project_env.sh
RUN chown nobody:nogroup /opt/project_env.sh
RUN chmod +x /opt/project_env.sh

COPY .docker/entrypoints/* /usr/local/bin/
RUN chmod +x /usr/local/bin/crontab.sh

COPY composer.json ./
COPY composer.lock ./

RUN php8.1 /usr/local/bin/composer install --no-dev --no-progress --no-scripts

COPY . /var/www

RUN php8.1 /usr/local/bin/composer dump-autoload --optimize

ARG APP_VERSION=0.0.0
ENV APP_VERSION ${APP_VERSION}

RUN echo APP_VERSION=${APP_VERSION} >> /var/www/.env.local

RUN mkdir -p /var/www/var/cache && chmod -R 1777 /var/www/var/cache && chown -R www-data:www-data /var/www/var/cache
RUN mkdir -p /var/www/var/log && chmod -R 1777 /var/www/var/log && chown -R www-data:www-data /var/www/var/log
RUN chmod +x /var/www/.docker/docker_migrate_apache.sh

USER www-data

CMD ["/var/www/.docker/docker_migrate_apache.sh"]
