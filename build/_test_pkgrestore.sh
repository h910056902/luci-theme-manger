#!/bin/sh
B=http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
H="Cookie: sysauth=$SID"
G() { curl -s -m 20 -H "$H" "$B?action=pkg_restore"; }
P() { curl -s -m 20 -X POST -H "$H" -d "op=$1" "$B?action=pkg_restore"; }

echo "== 1. 无清单时 =="
rm -rf /etc/kp-restore
G; echo
P start; echo

echo "== 2. 放入当前清单（应 total=0，秒完）=="
mkdir -p /etc/kp-restore
opkg list-installed > /etc/kp-restore/packages.txt
P start; echo
sleep 12
G; echo

echo "== 3. 塞一个不存在的包，测 FAIL 计数 =="
echo "no-such-pkg-xyz - 9.9" >> /etc/kp-restore/packages.txt
rm -f /tmp/kp-pkgrestore.state
P start; echo
sleep 20
G; echo

echo "== 4. 清理测试残留 =="
rm -rf /etc/kp-restore /tmp/kp-pkgrestore.* /tmp/kp-have.txt /tmp/kp-want.txt /tmp/kp-miss.txt
echo DONE
