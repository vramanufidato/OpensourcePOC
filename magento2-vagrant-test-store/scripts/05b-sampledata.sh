#!/usr/bin/env bash
set -e
cd /var/www/magento2
echo "=== sampledata:deploy ==="
php bin/magento sampledata:deploy -n 2>&1 | tail -25
echo "=== setup:upgrade ==="
php bin/magento setup:upgrade 2>&1 | tail -15
echo "=== setup:di:compile ==="
php bin/magento setup:di:compile 2>&1 | tail -10
echo "=== static content deploy ==="
php bin/magento setup:static-content:deploy -f en_US 2>&1 | tail -10
echo "=== reindex ==="
php bin/magento indexer:reindex 2>&1 | tail -25
echo "=== cache flush ==="
php bin/magento cache:flush
echo "=== SAMPLEDATA PIPELINE COMPLETE ==="