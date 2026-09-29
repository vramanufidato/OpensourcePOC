#!/usr/bin/env bash
# Verify the test order is visible to the admin.
# (Admin > Sales > Orders reads its grid from sales_order_grid.)
set -e
cd /var/www/magento2

echo "=== Order in sales_order_grid (Admin > Sales > Orders data source) ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT increment_id, status, grand_total, customer_email, billing_name FROM sales_order_grid ORDER BY entity_id DESC LIMIT 4;"

echo "=== Payment record (mock payment: checkmo, nothing captured) ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT p.method, p.amount_ordered, p.amount_paid, s.increment_id FROM sales_order_payment p JOIN sales_order s ON s.entity_id=p.parent_id WHERE s.increment_id='000000003';"

echo "=== Order items ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT sku, name, qty_ordered, price, row_total FROM sales_order_item WHERE order_id=(SELECT entity_id FROM sales_order WHERE increment_id='000000003');"
