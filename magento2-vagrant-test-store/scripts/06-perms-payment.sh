#!/usr/bin/env bash
set -e
cd /var/www/magento2
echo "=== Permissions (shared group + ACL for www-data and vagrant) ==="
sudo apt-get install -y -q acl > /dev/null
sudo chown -R vagrant:www-data /var/www/magento2
sudo find /var/www/magento2 -type d -exec chmod 775 {} \;
sudo find /var/www/magento2 -type f -exec chmod 664 {} \;
sudo chmod u+x bin/magento
sudo setfacl -R -m g:www-data:rwx -m u:vagrant:rwx var generated pub/static pub/media app/etc
sudo setfacl -R -d -m g:www-data:rwx -d -m u:vagrant:rwx var generated pub/static pub/media app/etc
echo "=== Cron for Magento (as www-data) ==="
sudo -u www-data -H php bin/magento cron:install 2>/dev/null || php bin/magento cron:install
echo "=== Payment: Check / Money Order (mock payment, no real processing) ==="
php bin/magento config:set payment/checkmo/active 1
php bin/magento config:set payment/checkmo/title "Check / Money Order (Test)"
php bin/magento config:set payment/checkmo/order_status pending
php bin/magento config:set checkout/options/guest_checkout 1
echo "=== Shipping: enable Flat Rate (for test checkout) ==="
php bin/magento config:set carriers/flatrate/active 1
php bin/magento config:set carriers/flatrate/title "Flat Rate (Test)"
php bin/magento cache:flush > /dev/null
printf 'checkmo active = %s\n' "$(php bin/magento config:show payment/checkmo/active)"
printf 'flatrate active = %s\n' "$(php bin/magento config:show carriers/flatrate/active)"
printf 'guest checkout = %s\n' "$(php bin/magento config:show checkout/options/guest_checkout)"
echo "=== CRONTAB ==="
sudo crontab -u www-data -l 2>/dev/null | head -8 || crontab -l | head -8