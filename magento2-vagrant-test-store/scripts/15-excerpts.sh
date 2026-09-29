#!/usr/bin/env bash
echo "-----INSTALLLOG-----"
tail -n 40 /home/vagrant/install.log
echo "-----PIPELOG-----"
grep -E "Upgrade completed|Generated code|indexers are indexed|rebuilt successfully|SAMPLEDATA PIPELINE COMPLETE|Sample data modules have been added" /home/vagrant/pipeline.log | head -22
echo "-----GRID-----"
mysql -u magento_user -pmagento_password -h 127.0.0.1 magento -e "SELECT increment_id, status, grand_total, customer_email FROM sales_order_grid ORDER BY entity_id DESC LIMIT 3;"