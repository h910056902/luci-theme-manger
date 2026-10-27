#!/bin/sh
mkdir -p /etc/openclash/config /etc/openclash/history /etc/openclash/rule_provider
chmod 755 /etc/openclash/config /etc/openclash/history
chmod 755 /etc/openclash/core/clash_meta
uci set openclash.config.enable='1'
uci set openclash.config.config_path='/etc/openclash/config/e_bbydy.yaml'
uci commit openclash
chmod 755 /etc/init.d/openclash
/etc/init.d/openclash enable 2>/dev/null
echo "starting..."
/etc/init.d/openclash restart >/tmp/oc-restart.log 2>&1 &
echo "pid=$!"
