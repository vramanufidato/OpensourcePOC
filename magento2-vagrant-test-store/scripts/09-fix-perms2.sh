#!/usr/bin/env bash
set -e
echo "=== Kill orphaned chmod find (safe) ==="
sudo pkill -f "find /var/www/magento2" || true
sleep 1
cd /var/www/magento2
echo "=== bin/magento executable ==="
sudo chmod u+x bin/magento
echo "=== ACLs on writable dirs ==="
sudo setfacl -R -m g:www-data:rwx -m u:vagrant:rwx var generated pub/static pub/media app/etc
sudo setfacl -R -d -m g:www-data:rwx -d -m u:vagrant:rwx var generated pub/static pub/media app/etc
echo "=== www-data write test ==="
sudo -u www-data touch /var/www/magento2/var/.www-write-test && rm /var/www/magento2/var/.www-write-test && echo "www-data CAN write var/"
echo "=== Cron install (as www-data) ==="
sudo -u www-data -H php bin/magento cron:install 2>/dev/null || php bin/magento cron:install
echo "=== Payment config (checkmo = mock payment) ==="
php bin/magento config:set payment/checkmo/active 1
php bin/magento config:set payment/checkmo/title "Check / Money Order (Test)"
php bin/magento config:set payment/checkmo/order_status pending
php bin/magento config:set checkout/options/guest_checkout 1
echo "=== Flat Rate shipping for test checkout ==="
php bin/magento config:set carriers/flatrate/active 1
php bin/magento config:set carriers/flatrate/title "Flat Rate (Test)"
php bin/magento cache:flush
printf 'checkmo active = %s\n' "$(php bin/magento config:show payment/checkmo/active)"
printf 'flatrate active = %s\n' "$(php bin/magento config:show carriers/flatrate/active)"
printf 'guest checkout = %s\n' "$(php bin/magento config:show checkout/options/guest_checkout)"
echo "=== CRONTAB (www-data) ==="
sudo crontab -u www-data -l 2>/dev/null | head -8 || true
echo "=== FIX-PERMS2 COMPLETE ==="