#!/bin/sh
rm -f /tmp/rc2.ck
curl -s -c /tmp/rc2.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://127.0.0.1/cgi-bin/luci/

echo "== 点击「备份全部分区」= ?do=backup =="
curl -s -b /tmp/rc2.ck -o /dev/null -m 20 \
	-w "  code=%{http_code} redirect=%{redirect_url}\n" \
	"http://127.0.0.1/cgi-bin/luci/admin/system/recovery?do=backup"

sleep 4
echo "== 进度 =="
/usr/bin/kp-recovery status

echo "== 备份目录数量 =="
ls -d /overlay/kp-fw-backup/*/ 2>/dev/null | wc -l

echo "== 导出 U-Boot 环境动作 =="
curl -s -b /tmp/rc2.ck -o /dev/null -m 15 -w "  code=%{http_code} redirect=%{redirect_url}\n" \
	"http://127.0.0.1/cgi-bin/luci/admin/system/recovery?do=env"
sleep 1
head -3 /tmp/uboot-env.txt 2>/dev/null
