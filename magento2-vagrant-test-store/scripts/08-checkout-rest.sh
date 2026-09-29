#!/usr/bin/env bash
set -e
BASE=http://127.0.0.1
echo "=== jq check ==="
command -v jq >/dev/null || sudo apt-get install -y -q jq > /dev/null
echo "=== pick a sample SKU from DB ==="
SKU=$(mysql -N -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT sku FROM catalog_product_entity WHERE type_id='simple' AND sku IN ('24-MB01','24-MB02','24-WB01','24-UG01') LIMIT 1;")
if [ -z "$SKU" ]; then SKU=$(mysql -N -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT sku FROM catalog_product_entity WHERE type_id='simple' LIMIT 1;"); fi
echo "SKU: $SKU"
echo "=== create guest cart ==="
CART=$(curl -s -m 60 -X POST "$BASE/rest/V1/guest-carts" -H 'Content-Type: application/json' -d '{}' | tr -d '"')
echo "CART: $CART"
echo "=== add item to cart ==="
curl -s -m 60 -X POST "$BASE/rest/V1/guest-carts/$CART/items" -H 'Content-Type: application/json' -d "{\"cartItem\":{\"quote_id\":\"$CART\",\"sku\":\"$SKU\",\"qty\":1}}" -o /tmp/additem.json
head -c 300 /tmp/additem.json; echo
echo "=== cart totals ==="
curl -s -m 60 "$BASE/rest/V1/guest-carts/$CART/totals" | jq -r '.grand_total // "n/a", (.items[0].name // "n/a"), (.items[0].qty // "n/a")'
echo "=== estimate shipping methods ==="
curl -s -m 60 -X POST "$BASE/rest/V1/guest-carts/$CART/estimate-shipping-methods" -H 'Content-Type: application/json' -d '{"address":{"country_id":"US","postcode":"90210","region":"California"}}' -o /tmp/ship.json
head -c 500 /tmp/ship.json; echo
CARRIER=$(jq -r '.[0].carrier_code // "flatrate"' /tmp/ship.json 2>/dev/null || echo flatrate)
METHOD=$(jq -r '.[0].method_code // "flatrate"' /tmp/ship.json 2>/dev/null || echo flatrate)
echo "using $CARRIER / $METHOD"
echo "=== set shipping information ==="
cat > /tmp/shipinfo.json <<EOF
{"addressInformation":{"shipping_address":{"region":"California","region_id":12,"country_id":"US","street":["1 Test Lane"],"postcode":"90210","city":"Beverly Hills","firstname":"Test","lastname":"Buyer","email":"guest@example.com","telephone":"555-555-5555"},"billing_address":{"region":"California","region_id":12,"country_id":"US","street":["1 Test Lane"],"postcode":"90210","city":"Beverly Hills","firstname":"Test","lastname":"Buyer","email":"guest@example.com","telephone":"555-555-5555"},"shipping_carrier_code":"$CARRIER","shipping_method_code":"$METHOD"}}
EOF
curl -s -m 60 -X POST "$BASE/rest/V1/guest-carts/$CART/shipping-information" -H 'Content-Type: application/json' --data @/tmp/shipinfo.json -o /tmp/paym.json
jq -r '.payment_methods[].code' /tmp/paym.json 2>/dev/null || head -c 400 /tmp/paym.json
echo "=== place order with checkmo (mock payment) ==="
cat > /tmp/payinfo.json <<EOF
{"email":"guest@example.com","paymentMethod":{"method":"checkmo"},"billing_address":{"region":"California","region_id":12,"country_id":"US","street":["1 Test Lane"],"postcode":"90210","city":"Beverly Hills","firstname":"Test","lastname":"Buyer","email":"guest@example.com","telephone":"555-555-5555"}}
EOF
ORDER=$(curl -s -m 120 -X POST "$BASE/rest/V1/guest-carts/$CART/payment-information" -H 'Content-Type: application/json' --data @/tmp/payinfo.json | tr -d '"')
echo "ORDER RESULT: $ORDER"
echo "=== verify order in DB ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT increment_id, state, status, grand_total, customer_email FROM sales_order ORDER BY entity_id DESC LIMIT 3;"