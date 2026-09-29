#!/usr/bin/env bash
cd /var/www/magento2
echo "=== 2FA module now ==="
php bin/magento module:status Magento_TwoFactorAuth 2>&1 | tail -2
echo "=== storefront ==="
curl -s -m 60 -o /dev/null -w "home: HTTP %{http_code} in %{time_total}s\n" -H "Host: localhost:8080" http://127.0.0.1/
curl -s -m 60 -o /dev/null -w "gear: HTTP %{http_code}\n" -H "Host: localhost:8080" http://127.0.0.1/gear.html
curl -s -m 60 -o /dev/null -w "duffle: HTTP %{http_code}\n" -H "Host: localhost:8080" http://127.0.0.1/joust-duffle-bag.html
curl -s -m 60 -o /dev/null -w "admin: HTTP %{http_code}\n" -H "Host: localhost:8080" http://127.0.0.1/admin
echo "=== product page title ==="
curl -s -m 60 -H "Host: localhost:8080" http://127.0.0.1/joust-duffle-bag.html | grep -o "<title>[^<]*</title>" | head -1
echo "=== services ==="
systemctl is-active mariadb elasticsearch apache2
echo "=== ES health ==="
curl -s -m 10 http://127.0.0.1:9200/_cluster/health | head -c 200
echo
echo "=== FINAL CHECK DONE ==="