#!/usr/bin/env bash
set -e

# Use PORT provided by Render or default to 80
PORT="${PORT:-80}"
sed -i "s/80/$PORT/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Add reverse proxy for Laravel Reverb WebSockets
sed -i '/<\/VirtualHost>/i \    ProxyPass "/app" "ws://127.0.0.1:8080/app"\n    ProxyPassReverse "/app" "ws://127.0.0.1:8080/app"\n    ProxyPass "/apps" "http://127.0.0.1:8080/apps"\n    ProxyPassReverse "/apps" "http://127.0.0.1:8080/apps"' /etc/apache2/sites-available/000-default.conf

echo "Starting deployment scripts..."

# Run migrations (Optional but highly recommended for auto-deployment)
php artisan migrate --force || true

# Cache configurations
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# Fix permissions after generating cache and running migrations as root
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "Setup complete."
