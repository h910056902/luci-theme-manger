#!/bin/sh
echo "== sysupgrade 参数 =="
sysupgrade -h 2>&1 | head -25

echo "== 配置备份里最大的几个条目 =="
rm -f /tmp/kp-cfg.tar.gz
sysupgrade -b /tmp/kp-cfg.tar.gz >/dev/null 2>&1
ls -lh /tmp/kp-cfg.tar.gz 2>/dev/null
tar -tzvf /tmp/kp-cfg.tar.gz 2>/dev/null | sort -k3 -n -r | head -8

echo "== 面板目录构成（前几项）=="
du -sh /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null
du -sm /overlay/nradio-apps/openwrt-luci-8080/* 2>/dev/null | sort -n -r | head -6

echo "== 现有 ipk =="
ls -lh /root/pkgs/*.ipk /tmp/*.ipk 2>/dev/null | tail -5
