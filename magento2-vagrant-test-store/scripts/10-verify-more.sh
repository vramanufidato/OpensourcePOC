#!/usr/bin/env bash
echo "=== storefront title ==="
curl -s -m 30 -H "Host: localhost:8080" http://127.0.0.1/ | grep -o "<title>[^<]*</title>" | head -2
echo "=== storefront content size ==="
curl -s -m 30 -H "Host: localhost:8080" http://127.0.0.1/ | wc -c
echo "=== storefront HTTP status ==="
curl -s -m 30 -o /dev/null -w "HTTP %{http_code} in %{time_total}s\n" -H "Host: localhost:8080" http://127.0.0.1/
echo "=== admin redirect ==="
curl -s -m 30 -o /dev/null -w "admin: %{http_code} -> %{redirect_url}\n" -H "Host: localhost:8080" http://127.0.0.1/admin
echo "=== admin final ==="
curl -s -L -m 30 -H "Host: localhost:8080" http://127.0.0.1/admin -o /tmp/admin.html -w "final: %{http_code}, size: %{size_download}\n"
grep -o "<title>[^<]*</title>" /tmp/admin.html | head -1
echo "=== MFA module status ==="
cd /var/www/magento2 && php bin/magento module:status Magento_TwoFactorAuth 2>&1 | tail -4
echo "=== ES ==="
systemctl is-active elasticsearch
curl -s -m 10 "http://127.0.0.1:9200/_cluster/health" | head -c 220
echo
echo "=== sample data sanity ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT (SELECT COUNT(*) FROM catalog_product_entity) AS products, (SELECT COUNT(*) FROM catalog_category_entity) AS categories, (SELECT COUNT(*) FROM customer_entity) AS customers, (SELECT COUNT(*) FROM sales_order) AS orders;"