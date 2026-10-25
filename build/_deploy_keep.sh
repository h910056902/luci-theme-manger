#!/bin/sh
[ -f /tmp/_up_keep ] || { echo "缺少 /tmp/_up_keep"; exit 1; }
tr -d '\r' < /tmp/_up_keep > /tmp/_up_keep.lf && mv /tmp/_up_keep.lf /tmp/_up_keep
mkdir -p /lib/upgrade/keep.d
cp /tmp/_up_keep /lib/upgrade/keep.d/nradio-luci-8080
chmod 644 /lib/upgrade/keep.d/nradio-luci-8080

echo "== 落盘 =="
ls -l /lib/upgrade/keep.d/nradio-luci-8080

echo "== 备份清单里是否出现 =="
for p in /etc/config/kpnet /etc/config/kpsmsfwd /etc/kpsmsfwd.body /etc/config/ttyd /etc/config/kaiplus; do
	[ -e "$p" ] || { echo "  跳过(不存在) $p"; continue; }
	if sysupgrade -l 2>/dev/null | grep -qx "$p"; then echo "  OK   $p"; else echo "  MISS $p"; fi
done

echo "== 备份文件总数 =="
sysupgrade -l 2>/dev/null | wc -l

echo "== 实测生成一次备份（看体积与是否含 body 模板）=="
rm -f /tmp/kp-backup-test.tar.gz
if sysupgrade -b /tmp/kp-backup-test.tar.gz >/tmp/kp-backup.log 2>&1; then
	ls -lh /tmp/kp-backup-test.tar.gz
	echo -n "含 kpsmsfwd.body: "; tar -tzf /tmp/kp-backup-test.tar.gz 2>/dev/null | grep -c 'kpsmsfwd.body'
	echo -n "含 kpnet:         "; tar -tzf /tmp/kp-backup-test.tar.gz 2>/dev/null | grep -c 'etc/config/kpnet'
	rm -f /tmp/kp-backup-test.tar.gz
else
	echo "生成失败:"; cat /tmp/kp-backup.log
fi
echo DONE
