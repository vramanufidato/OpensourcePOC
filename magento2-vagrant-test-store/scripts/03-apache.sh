#!/usr/bin/env bash
set -e
echo "=== Apache modules ==="
sudo a2enmod rewrite headers
echo "=== Magento vhost ==="
sudo tee /etc/apache2/sites-available/magento.conf > /dev/null <<'EOF'
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/magento2/pub
    <Directory /var/www/magento2/pub>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/magento-error.log
    CustomLog ${APACHE_LOG_DIR}/magento-access.log combined
</VirtualHost>
EOF
sudo a2dissite 000-default > /dev/null 2>&1 || true
sudo a2ensite magento > /dev/null
sudo systemctl enable apache2
sudo systemctl restart apache2
sleep 2
echo "apache2: $(systemctl is-active apache2)"