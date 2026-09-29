#!/usr/bin/env bash
set -e
echo "=== Preparing /var/www ==="
sudo chown vagrant:vagrant /var/www
cd /var/www
if [ -d magento2 ] && [ -z "$(ls -A magento2)" ]; then rmdir magento2; fi
echo "=== composer create-project via Mage-OS mirror (latest stable) ==="
composer create-project --no-interaction --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition magento2 2>&1 | tail -30
echo "=== Result ==="
ls /var/www/magento2 | head -25
php /var/www/magento2/bin/magento --version 2>&1 | head -3 || true
echo "=== repositories in composer.json ==="
php -r '$j=json_decode(file_get_contents("/var/www/magento2/composer.json"),true); var_export($j["repositories"]??null); echo PHP_EOL;'