#!/usr/bin/env bash
echo "=== PHP modules ==="
php -m | grep -Eiw 'bcmath|curl|gd|intl|mbstring|mysqli|pdo_mysql|soap|xsl|zip|opcache|sockets|ctype|iconv|openssl|simplexml|tokenizer' | sort | tr '\n' ' '
echo
echo "=== Services (active / enabled) ==="
for s in mariadb apache2 nginx elasticsearch; do printf '%-16s %s / %s\n' "$s" "$(systemctl is-active $s 2>/dev/null)" "$(systemctl is-enabled $s 2>/dev/null)"; done
echo "=== Ports ==="
ss -tln | grep -E ':(80|3306|9200)\s' || echo "(none listening on 80/3306/9200)"
echo "=== Versions ==="
php -v | head -1; apache2 -v | head -1; composer --version