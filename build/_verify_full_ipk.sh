#!/bin/sh
F=$(ls -t /overlay/kp-restore-*.ipk 2>/dev/null | head -1)
echo "包: $F"
echo "== 外层结构 =="
tar -tzf "$F"
echo "== data 关键路径 =="
T=/tmp/kpv.$$
mkdir -p "$T"
tar -xzf "$F" -C "$T" data.tar.gz 2>/dev/null
tar -tzf "$T/data.tar.gz" 2>/dev/null | awk -F/ '
  /^\.\/overlay\/nradio-apps/ {a++}
  /^\.\/etc\/openclash\// {b++}
  /^\.\/etc\/config\// {c++}
  /^\.\/etc\/kp-restore\// {d++}
  END { printf "  面板文件: %d\n  openclash 文件: %d\n  配置项: %d\n  kp-restore: %d\n", a, b, c, d }'
echo "== 订阅配置是否在包里（只看键名不看值）=="
tar -xzOf "$T/data.tar.gz" ./etc/config/openclash 2>/dev/null | grep -oE "option (config_path|enable|en_mode|servers_update|subscription[a-z_]*)" | sort -u | head -8
echo -n "config 行数: "; tar -xzOf "$T/data.tar.gz" ./etc/config/openclash 2>/dev/null | wc -l
echo "== control =="
tar -xzOf "$T/control.tar.gz" ./control 2>/dev/null
rm -rf "$T"
echo DONE
