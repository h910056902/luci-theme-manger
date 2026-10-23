#!/bin/sh
F=/usr/lib/lua/luci/view/ttyd/overview.htm
echo "== 行号 / 长度 / 行首 70 字符 =="
awk '{ printf "%3d  %8d  %s\n", NR, length($0), substr($0, 1, 70) }' "$F"
