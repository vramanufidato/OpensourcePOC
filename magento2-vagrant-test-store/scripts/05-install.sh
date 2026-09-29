#!/usr/bin/env bash
set -e
cd /var/www/magento2
echo "=== bin/magento setup:install ==="
php bin/magento setup:install -n \
  --base-url=http://localhost:8080/ \
  --db-host=127.0.0.1 \
  --db-name=magento \
  --db-user=magento_user \
  --db-password=magento_password \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin \
  --admin-password='Admin123!' \
  --language=en_US \
  --currency=USD \
  --timezone=UTC \
  --use-rewrites=1 \
  --backend-frontname=admin \
  --search-engine=elasticsearch8 \
  --elasticsearch-host=127.0.0.1 \
  --elasticsearch-port=9200 2>&1 | tail -45
echo "=== install exit code: $? ==="
php bin/magento --version