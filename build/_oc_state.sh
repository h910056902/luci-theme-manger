#!/bin/sh
echo "== core 目录 =="
ls -l /etc/openclash/core/ 2>/dev/null || echo "  无 core 目录"
echo "== 相关进程 =="
ps w | grep -E '[c]lash|[o]penclash' | head -6
echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090|:7874' | head -8
echo "== 服务状态 =="
/etc/init.d/openclash status 2>&1 | head -3
uci -q get openclash.config.enable
echo "== 运行日志 =="
logread 2>/dev/null | grep -i openclash | tail -8
echo "== 内核可用性 =="
[ -x /etc/openclash/core/clash_meta ] && /etc/openclash/core/clash_meta -v 2>&1 | head -2 || echo "  内核不存在或不可执行"
echo "== 备份包里的 openclash 部分（确认是否含 core）=="
mkdir -p /tmp/bk && cd /tmp/bk || exit 1
tar -xzf /overlay/kp-restore-20261025-194209.ipk data.tar.gz 2>/dev/null
tar -tzf data.tar.gz 2>/dev/null | grep -c 'core/'
rm -rf /tmp/bk
