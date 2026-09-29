#!/usr/bin/env bash
set -e
echo "=== Adding Elastic APT repo (8.x) ==="
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update -q
echo "=== Installing Elasticsearch ==="
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -q elasticsearch
echo "=== Configuring: single node, no security, 512m heap ==="
sudo cp -n /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.dist || true
sudo sed -i -E 's/^(xpack\..*)$/# \1/' /etc/elasticsearch/elasticsearch.yml
printf '%s\n' 'network.host: 127.0.0.1' 'discovery.type: single-node' 'xpack.security.enabled: false' 'xpack.ml.enabled: false' | sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null
sudo mkdir -p /etc/elasticsearch/jvm.options.d
printf '%s\n' '-Xms512m' '-Xmx512m' | sudo tee /etc/elasticsearch/jvm.options.d/heap.options > /dev/null
sudo chown root:elasticsearch /etc/elasticsearch/jvm.options.d/heap.options
sudo chmod 660 /etc/elasticsearch/jvm.options.d/heap.options
echo "=== Starting Elasticsearch ==="
sudo systemctl daemon-reload
sudo systemctl enable --now elasticsearch
echo "=== Waiting for ES (up to 150s) ==="
for i in $(seq 1 30); do
  r=$(curl -s http://127.0.0.1:9200 || true)
  if [ -n "$r" ]; then echo "$r" | head -8; echo "ES OK after ~$((i*5))s"; exit 0; fi
  sleep 5
done
echo "ES NOT RESPONDING within timeout"; sudo systemctl status elasticsearch --no-pager | head -12; exit 1