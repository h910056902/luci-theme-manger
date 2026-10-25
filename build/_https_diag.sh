#!/bin/sh
echo "== 证书文件 =="
ls -l /etc/uhttpd.crt /etc/uhttpd.key 2>/dev/null || echo "  证书缺失"

echo "== uhttpd 监听 =="
netstat -lnt 2>/dev/null | grep -E ':80|:443'
ps w | grep '[u]httpd' | head -2

echo "== init 里的证书生成逻辑 =="
grep -nE 'keygen|px5g|openssl|uhttpd.crt|listen_https' /etc/init.d/uhttpd 2>/dev/null | head -12

echo "== 生成工具 =="
command -v px5g >/dev/null && echo "  px5g: 有" || echo "  px5g: 无"
command -v openssl >/dev/null && echo "  openssl: 有" || echo "  openssl: 无"

echo "== uci https 配置 =="
uci -q get uhttpd.main.listen_https
uci -q get uhttpd.main.redirect_https
uci -q get uhttpd.main.cert
uci -q get uhttpd.main.key

echo "== 启动日志 =="
logread 2>/dev/null | grep -iE 'uhttpd' | tail -6
