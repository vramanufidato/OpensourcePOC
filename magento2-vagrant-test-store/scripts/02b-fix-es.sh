#!/usr/bin/env bash
set -e
echo "=== Backup current config ==="
sudo cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.pre-fix 2>/dev/null || true
echo "=== Write clean minimal config ==="
sudo tee /etc/elasticsearch/elasticsearch.yml > /dev/null <<'EOF'
# Minimal config for Magento dev/test use (security disabled, single node)
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
cluster.name: magento-es
node.name: node-1
network.host: 127.0.0.1
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
xpack.ml.enabled: false
EOF
sudo chown root:elasticsearch /etc/elasticsearch/elasticsearch.yml
sudo chmod 660 /etc/elasticsearch/elasticsearch.yml
echo "=== Restart ES ==="
sudo systemctl enable elasticsearch > /dev/null 2>&1
sudo systemctl restart elasticsearch || true
echo "=== Wait for ES (up to 150s) ==="
for i in $(seq 1 30); do
  r=$(curl -s http://127.0.0.1:9200 || true)
  if [ -n "$r" ]; then echo "$r" | head -10; echo "ES OK after ~$((i*5))s"; exit 0; fi
  sleep 5
done
echo "ES NOT RESPONDING"; sudo journalctl -u elasticsearch --no-pager -n 30; exit 1