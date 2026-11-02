#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
echo "== 总体积 =="
du -sk $D 2>/dev/null
echo "== 各子目录体积 =="
du -sk $D/* 2>/dev/null
echo "== 文件数 =="
find $D -type f 2>/dev/null | wc -l
echo "== 顶级目录 =="
ls -la $D
echo "== www 结构（2 层） =="
find $D/www -maxdepth 2 -type d 2>/dev/null | head -20
echo "== 视图目录 =="
find $D/usr/lib/lua/luci/view -maxdepth 2 -name '*.htm' 2>/dev/null | sed "s#$D##" | sort | head -40
echo "== 视图数量 =="
find $D/usr/lib/lua/luci/view -name '*.htm' 2>/dev/null | wc -l
echo "== 控制器覆盖 =="
find $D/usr/lib/lua/luci/controller -name '*.lua' 2>/dev/null | sed "s#$D##" | head -20
echo "== luci-static 自定义文件 =="
find $D/www/luci-static -type f 2>/dev/null | grep -vE 'openclash/ui/|quickstart/(i18n|assets)' | sed "s#$D##" | head -40
echo "== 外部依赖（/www、共享 lua）关键文件时间 =="
ls -l /www/luci-static/nradio/images/icon/ocspeed.png /usr/lib/lua/luci/view/ocspeed.htm /usr/lib/lua/luci/view/nodetest.htm 2>/dev/null
