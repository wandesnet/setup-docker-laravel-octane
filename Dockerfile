FROM php:8.1-fpm

# Arguments defined in docker-compose.yml
ARG user=app
ARG uid=1000

ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
ENV PHP_OPCACHE_REVALIDATE_FREQ=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    cron \
    supervisor \
    ghostscript \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    libpq-dev \
    libmagickwand-dev --no-install-recommends && \
    pecl install imagick && docker-php-ext-enable imagick && docker-php-ext-configure intl \
    && docker-php-ext-install intl

#install swoole
RUN pecl install swoole
RUN docker-php-ext-enable swoole

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs
RUN npm install --save-dev chokidar

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install calendar zip pdo opcache pdo_pgsql xml pgsql mbstring exif pcntl bcmath gd sockets

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

#upload
RUN echo "file_uploads = On\n" \
         "memory_limit = 500M\n" \
         "upload_max_filesize =440M\n" \
         "post_max_size = 450M\n" \
         "max_execution_time = 5000\n" \
         "max_input_vars=1000\n" \
         > /usr/local/etc/php/conf.d/uploads.ini

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && mkdir -p /home/$user/.supervisor && \
    chown -R $user:$user /home/$user

RUN chown -R www-data:www-data /var/www

# Install redis
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

COPY ./docker/imageMagick/policy.xml /etc/ImageMagick-6/policy.xml
COPY ./docker/php/php.ini /usr/local/etc/php/php.ini
COPY ./docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

#supervisor
COPY ./docker/supervisor/start-supervisor /usr/local/bin/start-supervisor
COPY ./docker/supervisor/workers.conf /etc/supervisor/conf.d/workers.conf
RUN chmod +x /usr/local/bin/start-supervisor

#crontab
COPY ./docker/crontab/scheduler /etc/cron.d/scheduler
RUN chmod 0644 /etc/cron.d/scheduler
RUN crontab /etc/cron.d/scheduler
RUN chmod u+s /usr/sbin/cron
 
# Set working directory
WORKDIR /var/www

USER $user
