#!/bin/sh
IPK=$(ls -t /overlay/kp-restore-*.ipk 2>/dev/null | head -1)
[ -n "$IPK" ] || IPK=/tmp/kp-restore.ipk
echo "恢复包: $IPK"
[ -f "$IPK" ] || { echo "缺少恢复包，终止"; exit 1; }

rm -rf /tmp/ocx && mkdir -p /tmp/ocx && cd /tmp/ocx || exit 1
tar -xzf "$IPK" data.tar.gz || { echo "解包失败"; exit 1; }
echo "== 包内 openclash 条目数 =="
tar -tzf data.tar.gz 2>/dev/null | grep -c openclash

echo "== 解到根目录 =="
tar -xzf data.tar.gz \
	./etc/openclash ./etc/config/openclash ./etc/init.d/openclash \
	./usr/share/openclash ./usr/lib/lua/luci/controller/openclash.lua \
	./usr/lib/lua/luci/view/openclash ./usr/lib/lua/luci/model/cbi/openclash \
	./www/luci-static/resources/openclash -C / 2>&1 | head -5

echo "== 校验 =="
ls -l /etc/init.d/openclash /usr/lib/lua/luci/controller/openclash.lua 2>/dev/null
ls -l /etc/openclash/core/clash_meta 2>/dev/null
du -sm /etc/openclash /usr/share/openclash /www/luci-static/resources/openclash 2>/dev/null

echo "== 启动服务 =="
/etc/init.d/openclash enable 2>/dev/null
/etc/init.d/openclash restart >/dev/null 2>&1
sleep 4
if pidof openclash >/dev/null 2>&1; then
	echo "  openclash 运行中: $(pidof openclash)"
else
	echo "  openclash 未运行"
	logread 2>/dev/null | grep -i openclash | tail -5
fi

echo "== 配置检查 =="
uci show openclash 2>/dev/null | head -8
rm -rf /tmp/ocx
