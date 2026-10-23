#!/bin/sh
# 用 LuCI/iStoreOS 自带的 ttyd 前端（view/ttyd/overview.htm）改造出 8080 的内嵌终端页。
# 它是自包含的：xterm.js + fit 插件 + UTF8 解码 + WS 连接逻辑全部内联，
# 不依赖 ttyd 的 React 前端，只依赖 ttyd 的后端 WebSocket。

set -e
D=/overlay/nradio-apps/openwrt-luci-8080
SRC=/usr/lib/lua/luci/view/ttyd/overview.htm
DST=$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm
TS=$(date +%Y%m%d-%H%M%S)

[ -f "$SRC" ] || { echo "缺少参考实现 $SRC"; exit 1; }
cp "$DST" "/tmp/kpc-term-$TS.htm" 2>/dev/null || true
echo "备份: /tmp/kpc-term-$TS.htm"

cp "$SRC" "$DST"

# 1) CSS 从 Lua 变量改为直接输出（否则样式不生效）
sed -i 's|^<% css = \[\[$|<% local kp_term_css = [[|' "$DST"
sed -i 's|^]] -%>$|]] -%>\n<style type="text/css"><%=kp_term_css%></style>|' "$DST"

# 2) 页面标题（iStoreOS 里这块由 LuCI 页面标题提供）
sed -i 's|<%+header%>|<%+header%>\n\n<h2 name="content">终端</h2>|' "$DST"

# 3) 始终显示终端（不做 is_running 分支，ttyd 掉线由页面自身提示）
sed -i 's|<% if is_running == 1 then %>|<% local is_running = 1 %><% if is_running == 1 then %>|' "$DST"

# 4) auth_token.js 在 8080 实例不存在 → 内联空 token
sed -i 's|<script src="auth_token.js"></script>|<script>var tty_auth_token = null;</script>|' "$DST"

# 5) 关键修复：LuCI 在 80 端口，window.location.host 不含端口；
#    8080 实例的 host 是 "IP:8080"，拼上 :7681 会变成 "IP:8080:7681"
sed -i 's|window.location.host+|window.location.hostname+|g' "$DST"

# 6) 终端高度：参考页是 80vh（上方有 LuCI 标题栏），这里让它在剩余空间里铺满
sed -i 's|#terminal-container{height:80vh;min-height:80vh;|#terminal-container{height:calc(100vh - 168px);min-height:420px;|' "$DST"

chmod 644 "$DST"

echo "== 校验 =="
echo -n "文件大小: "; wc -c < "$DST"
echo -n "kp_term_css 输出: "; grep -c 'kp_term_css' "$DST"
echo -n "hostname 修复: "; grep -c 'window.location.hostname' "$DST"
echo -n "auth_token 内联: "; grep -c 'tty_auth_token = null' "$DST"
echo -n "标题: "; grep -c '>终端</h2>' "$DST"
echo -n "残留 80vh: "; grep -c 'height:80vh' "$DST" || true
echo DONE
