#!/usr/bin/env bash
set -e
cd /var/www/magento2
echo "=== sales_order_grid (admin Sales > Orders data source) ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT increment_id, status, grand_total, customer_email, billing_name FROM sales_order_grid ORDER BY entity_id DESC LIMIT 4;"
echo "=== payment method for order 000000003 ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT p.method, p.amount_ordered, p.amount_paid, s.increment_id FROM sales_order_payment p JOIN sales_order s ON s.entity_id=p.parent_id WHERE s.increment_id='000000003';"
echo "=== order items for 000000003 ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT sku, name, qty_ordered, price, row_total FROM sales_order_item WHERE order_id=(SELECT entity_id FROM sales_order WHERE increment_id='000000003');"
echo "=== Disable TwoFactorAuth for test store (reversible) ==="
for m in Magento_TwoFactorAuth Magento_AdminAdobeImsTwoFactorAuth; do
  if php bin/magento module:status "$m" > /dev/null 2>&1; then
    php bin/magento module:disable "$m" --force 2>/dev/null || php bin/magento module:disable "$m" || true
  else
    echo "not present: $m"
  fi
done
echo "=== setup:upgrade (module list refresh) ==="
php bin/magento setup:upgrade 2>&1 | tail -4
echo "=== static content deploy (admin theme refresh) ==="
php bin/magento setup:static-content:deploy -f en_US 2>&1 | tail -6
php bin/magento cache:flush
echo "=== TWFA-DONE ==="