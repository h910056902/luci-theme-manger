#!/bin/sh
echo "== 1. 型号 / 平台 / 内核 =="
cat /tmp/sysinfo/model 2>/dev/null
cat /tmp/sysinfo/board_name 2>/dev/null
uname -m
uname -r

echo "== 2. U-Boot 环境变量工具 =="
command -v fw_printenv fw_setenv 2>/dev/null || echo "  无 fw_printenv"

echo "== 3. 关键 U-Boot 变量 =="
fw_printenv 2>/dev/null | grep -E '^(bootcmd|bootdelay|bootmenu|bootargs|baudrate|ipaddr|serverip|bootfile|fdtfile|bootconf|mtdparts)=' | head -20 || echo "  读不到"

echo "== 4. 分区表 =="
cat /proc/mtd 2>/dev/null | head -20
echo "-- mtd 工具 --"
command -v mtd nanddump 2>/dev/null

echo "== 5. 安全启动 / 签名 =="
opkg list-installed 2>/dev/null | grep -E 'fit-check|image-check|uboot' | head -6

echo "== 6. 是否已有 Breed 痕迹 =="
ls /dev/mtd* 2>/dev/null | head -3
grep -ril 'breed' /etc/config /www 2>/dev/null | head -3 || echo "  无 breed 相关文件"

echo "== 7. 故障安全模式支持 =="
grep -E 'failsafe|preinit' /etc/preinit 2>/dev/null | head -3
ls /lib/preinit/ 2>/dev/null | grep -i failsafe

echo "== 8. 系统恢复相关入口 =="
cat /www/index.html 2>/dev/null | head -5
uci -q get luci.main.lang 2>/dev/null
