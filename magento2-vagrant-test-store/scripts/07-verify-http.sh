#!/usr/bin/env bash
echo "=== Storefront (guest loopback) ==="
curl -s -m 30 -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' http://127.0.0.1/
echo "=== Storefront (Host: localhost:8080) ==="
curl -s -m 30 -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: localhost:8080' http://127.0.0.1/
echo "=== Admin login page ==="
curl -s -m 30 -o /dev/null -w 'HTTP %{http_code}\n' http://127.0.0.1/admin
echo "=== Probe headers ==="
curl -sI -m 30 http://127.0.0.1/ | grep -i 'x-magento\|set-cookie' | head -6
echo "=== Admin page title probe ==="
curl -s -m 30 http://127.0.0.1/admin | grep -o '<title>[^<]*</title>' | head -2