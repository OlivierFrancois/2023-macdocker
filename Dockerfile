FROM php:8.1-apache-buster

ARG DOCKER_WHOAMI
ARG DOCKER_NODE_MAJOR

RUN apt-get update \
    && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${DOCKER_NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs

RUN apt-get update \
    && apt-get install -y libzip-dev git wget sudo vim --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN docker-php-ext-install pdo mysqli pdo_mysql zip;

RUN curl -sS https://getcomposer.org/installer | php -- \
    &&  mv composer.phar /usr/local/bin/composer

# Enable apache modules
RUN a2enmod rewrite

# Prepare fake SSL certificate
RUN apt-get update
RUN apt-get install -y ssl-cert

# Setup Apache2 mod_ssl
RUN a2enmod ssl

COPY template.conf /etc/apache2/sites-available/template.conf

RUN useradd -ms /bin/bash ${DOCKER_WHOAMI}
RUN usermod -aG sudo ${DOCKER_WHOAMI}
RUN adduser ${DOCKER_WHOAMI} www-data
RUN chown ${DOCKER_WHOAMI}:www-data /var/www -R
RUN echo 'alias sf="php bin/console"' >> /home/${DOCKER_WHOAMI}/.bashrc

WORKDIR /var/www
CMD ["apache2-foreground"]