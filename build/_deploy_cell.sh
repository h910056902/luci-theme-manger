#!/bin/sh
# 部署状态总览 + 蜂窝页到 8080 实例；语法检查失败自动回滚
set -e

ROOT=/overlay/nradio-apps/openwrt-luci-8080
DOC=$ROOT/www
VIEW=$ROOT/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-deploy-$TS

mkdir -p "$BAK"
cp "$DOC/cgi-bin/luci" "$BAK/luci" 2>/dev/null || true
cp "$VIEW/index.htm" "$BAK/index.htm" 2>/dev/null || true
cp "$VIEW/nradio_cellular.htm" "$BAK/nradio_cellular.htm" 2>/dev/null || true
echo "BAK=$BAK"

cp /tmp/kpc-upload-luci "$DOC/cgi-bin/luci"
chmod 755 "$DOC/cgi-bin/luci"
cp /tmp/kpc-upload-index.htm "$VIEW/index.htm"
cp /tmp/kpc-upload-cellular.htm "$VIEW/nradio_cellular.htm"
chmod 644 "$VIEW/index.htm" "$VIEW/nradio_cellular.htm"

if ! lua -e "assert(loadfile('$DOC/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
  cp "$BAK/luci" "$DOC/cgi-bin/luci"
  cp "$BAK/index.htm" "$VIEW/index.htm"
  cp "$BAK/nradio_cellular.htm" "$VIEW/nradio_cellular.htm"
  echo "SYNTAX_FAIL"
  cat /tmp/kpc-syntax.err
  exit 1
fi
echo "SYNTAX_OK"

ls -l "$DOC/cgi-bin/luci" "$VIEW/index.htm" "$VIEW/nradio_cellular.htm"
echo "MARK_poll=$(grep -c 'action == "poll"' "$DOC/cgi-bin/luci" || true)"
echo "MARK_at=$(grep -c 'KP_AT_ALLOW' "$DOC/cgi-bin/luci" || true)"
echo "MARK_tool=$(grep -c 'data-panel="tool"' "$VIEW/nradio_cellular.htm" || true)"
echo "MARK_trend=$(grep -c 'data-panel="trend"' "$VIEW/nradio_cellular.htm" || true)"
