#!/bin/sh
echo "== 源配置 =="
cat /etc/opkg/distfeeds.conf 2>/dev/null | head -6

echo "== 联网测试 =="
ping -c 1 -W 3 223.5.5.5 >/dev/null 2>&1 && echo "  ICMP 通" || echo "  ICMP 不通"
nslookup downloads.openwrt.org >/dev/null 2>&1 && echo "  DNS 通" || echo "  DNS 不通"

echo "== opkg 安装 px5g =="
opkg update >/tmp/opkgup.log 2>&1
tail -3 /tmp/opkgup.log
opkg install px5g 2>&1 | tail -6

echo "== 检查 =="
command -v px5g >/dev/null && echo "  px5g 已安装: $(command -v px5g)" || echo "  px5g 仍未安装"
ls -l /usr/sbin/px5g /usr/bin/px5g 2>/dev/null
