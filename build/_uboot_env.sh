#!/bin/sh
# 修复 fw_env 配置并读取 U-Boot 环境（只读，不改任何变量）
echo "== 1. 探测 nvmem =="
ls /sys/bus/nvmem/devices/ 2>/dev/null | head -5
for d in /sys/bus/nvmem/devices/*/; do
	[ -r "$d/nvmem" ] && echo "  nvmem: $d"
done

echo "== 2. 写 fw_env.config（仅影响工具读取）=="
cat > /etc/fw_env.config <<'EOF'
# MT7987 u-boot-env（mtd1, 64KB, 单备份）
/dev/mtd1 0x0 0x10000 0x10000
EOF
cat /etc/fw_env.config

echo "== 3. 读取环境 =="
fw_printenv 2>&1 | head -40

echo "== 4. 关键项 =="
for k in bootcmd bootdelay bootmenu bootargs ipaddr serverip bootfile mtdparts; do
	v=$(fw_printenv "$k" 2>/dev/null | sed "s/^$k=//")
	[ -n "$v" ] && printf "  %-10s %s\n" "$k" "$(echo "$v" | cut -c1-100)"
done
