#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci"
echo "== POST 登录响应头 =="
curl -s -i -m 20 -d "luci_username=root&luci_password=admin" "$B/" | head -25
echo
echo "== 登录页表单字段 =="
curl -s -m 20 "$B/" | grep -oE '<input[^>]*>' | head -10
echo
echo "== sysauth 相关配置 =="
uci -q get luci.main.session_backend
uci -q get @system[0].hostname
