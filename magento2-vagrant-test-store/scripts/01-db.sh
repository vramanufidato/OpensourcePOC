#!/usr/bin/env bash
set -e
echo "=== Enabling MariaDB ==="
sudo systemctl enable --now mariadb
sudo systemctl status mariadb --no-pager | head -4
echo "=== Allow remote bind (for host 3306 forward) ==="
sudo sed -i -E "s/^bind-address[[:space:]]*=.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true
grep -R "^bind-address" /etc/mysql/mariadb.conf.d/ | head -3 || true
sudo systemctl restart mariadb
echo "=== Creating database and user ==="
sudo mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS magento CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'magento_user'@'localhost' IDENTIFIED BY 'magento_password';
CREATE USER IF NOT EXISTS 'magento_user'@'127.0.0.1' IDENTIFIED BY 'magento_password';
CREATE USER IF NOT EXISTS 'magento_user'@'%' IDENTIFIED BY 'magento_password';
GRANT ALL PRIVILEGES ON magento.* TO 'magento_user'@'localhost';
GRANT ALL PRIVILEGES ON magento.* TO 'magento_user'@'127.0.0.1';
GRANT ALL PRIVILEGES ON magento.* TO 'magento_user'@'%';
FLUSH PRIVILEGES;
SQL
echo "=== Verify ==="
mysql -u magento_user -pmagento_password -h 127.0.0.1 -e "SELECT 'magento db ok' AS status; SHOW DATABASES LIKE 'magento';"