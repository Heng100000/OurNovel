#!/usr/bin/env bash
set -e

# Use PORT provided by Render or default to 80
PORT="${PORT:-80}"
sed -i "s/80/$PORT/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

echo "Starting deployment scripts..."

# Run migrations (Optional but highly recommended for auto-deployment)
php artisan migrate --force || true

# Cache configurations
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Setup complete. Supervisor will now start Apache and Reverb."

# Start the supervisor managed programs
supervisorctl start apache2
supervisorctl start reverb
