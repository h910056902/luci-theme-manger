#!/bin/sh
echo "== 安装证书 =="
cp /tmp/_up_uhttpd.crt /etc/uhttpd.crt
cp /tmp/_up_uhttpd.key /etc/uhttpd.key
chmod 644 /etc/uhttpd.crt
chmod 600 /etc/uhttpd.key
ls -l /etc/uhttpd.crt /etc/uhttpd.key

echo "== 校验证书可解析 =="
head -1 /etc/uhttpd.crt
head -1 /etc/uhttpd.key

echo "== 重启 uhttpd =="
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
ps w | grep '[u]httpd' | head -2

echo "== 监听 =="
netstat -lnt 2>/dev/null | grep -E ':80|:443'

echo "== 本机 HTTPS 测试 =="
curl -sk -o /dev/null -w "  https://127.0.0.1/ -> %{http_code}\n" https://127.0.0.1/ --max-time 8
curl -sk -o /dev/null -w "  https://192.168.66.1/ -> %{http_code}\n" https://192.168.66.1/ --max-time 8
