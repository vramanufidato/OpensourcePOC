#!/usr/bin/env bash
set -e
BIN=/usr/share/elasticsearch/bin/elasticsearch-keystore
echo "=== Keystore contents (before) ==="
sudo "$BIN" list || true
echo "=== Removing stale security keystore entries ==="
for k in xpack.security.transport.ssl.keystore.secure_password xpack.security.transport.ssl.truststore.secure_password xpack.security.http.ssl.keystore.secure_password xpack.security.http.ssl.truststore.secure_password; do
  sudo "$BIN" remove "$k" 2>/dev/null && echo "removed: $k" || echo "not present: $k"
done
echo "=== Keystore contents (after) ==="
sudo "$BIN" list || true
echo "=== Restart ES ==="
sudo systemctl restart elasticsearch
for i in $(seq 1 30); do
  r=$(curl -s http://127.0.0.1:9200 || true)
  if [ -n "$r" ]; then echo "$r" | head -10; echo "ES OK after ~$((i*5))s"; exit 0; fi
  sleep 5
done
echo "ES STILL NOT RESPONDING"; sudo journalctl -u elasticsearch --no-pager -n 20; exit 1