#!/bin/sh
# 商店侧真实安装测试：先卸载 → 通过 ubus appcenter install 让商店自己下载+安装 → 校验
# 失败自动回退到本地 opkg install，保证 8080 不长时间不可用
PKG=nradio-luci-8080
APP="LuCI 8080 面板"
IPK=/www/pkgs/${PKG}_20261022-1_all.ipk

echo "== 1. 卸载现有包 =="
opkg remove $PKG 2>&1
echo "REMOVE_RC=$?"
opkg list-installed | grep $PKG || echo "removed-ok"
curl -s -m 8 -o /dev/null -w "8080-after-remove=%{http_code}\n" http://192.168.66.1:8080/

echo "== 2. 商店安装（顶层应用名） =="
ubus call appcenter install "{\"name\":\"$APP\"}" 2>&1
sleep 8
opkg list-installed | grep $PKG || echo "not-yet"

if ! opkg list-installed | grep -q "$PKG"; then
    echo "== 2b. 商店安装（包名） =="
    ubus call appcenter install "{\"name\":\"$PKG\"}" 2>&1
    sleep 8
fi

echo "== 3. 结果 =="
opkg list-installed | grep $PKG || echo "STILL-NOT-INSTALLED"
curl -s -m 10 -o /dev/null -w "8080-after-install=%{http_code}\n" http://192.168.66.1:8080/
curl -s -m 10 -o /dev/null -w "details=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details

echo "== 4. 商店状态字段 =="
ubus call appcenter list 2>/dev/null | grep -A4 "\"nradio-luci-8080\"" | head -12

echo "== 5. 商店日志 =="
logread 2>/dev/null | grep -i "appcenter\|opkg" | tail -12

echo "== 6. 兜底恢复 =="
if ! opkg list-installed | grep -q "$PKG"; then
    echo "FALLBACK opkg install"
    opkg install "$IPK" 2>&1
fi
opkg list-installed | grep $PKG || echo "FINAL-FAIL"
echo "DONE"
