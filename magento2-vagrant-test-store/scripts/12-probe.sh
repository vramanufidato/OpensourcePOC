#!/usr/bin/env bash
printf 'count_curl_11: %s\n' "$(grep -c 'curl' /vagrant/magento-setup/11-admin-verify.sh)"
printf 'count_adminpwd_11: %s\n' "$(grep -c 'Admin123' /vagrant/magento-setup/11-admin-verify.sh)"
printf 'count_adminpwd_05: %s\n' "$(grep -c 'Admin123' /vagrant/magento-setup/05-install.sh)"
awk 'NR==5 {print "line5_len_11:", length($0)}' /vagrant/magento-setup/11-admin-verify.sh
if bash -n /vagrant/magento-setup/11-admin-verify.sh 2>/tmp/syn.err; then echo 'syntax_11: OK'; else echo 'syntax_11: FAIL'; head -2 /tmp/syn.err; fi