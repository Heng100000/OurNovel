# Base image
FROM php:8.4-apache

# Set environment variables
ENV NODE_VERSION=20.x
ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Update and install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    supervisor \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    gd \
    zip \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    intl \
    bcmath \
    exif \
    pcntl \
    opcache

# Enable Apache modules
RUN a2enmod rewrite proxy proxy_http proxy_wstunnel

# Configure Apache DocumentRoot
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# 1. Copy composer files first for layer caching
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-scripts --no-interaction --prefer-dist --optimize-autoloader

# 2. Copy package files for npm layer caching
COPY package*.json ./

# Install npm dependencies
RUN npm install

# 3. Copy the rest of the application
COPY . .

# 4. Prepare Laravel for Wayfinder build
# Copy production env if it exists, otherwise use example
RUN if [ -f ".env.pro" ]; then cp .env.pro .env; else cp .env.example .env; fi

# Generate autoloader and run Wayfinder required steps
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# 5. Build assets
RUN npm run build

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy configurations
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose ports
EXPOSE 80 8080

# Start supervisor
CMD ["/usr/local/bin/start.sh"]
