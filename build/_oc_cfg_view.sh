#!/bin/sh
echo "== 下载状态 =="
cat /overlay/oc-core.state 2>/dev/null || echo "  无 state"
tail -4 /overlay/oc-core.log 2>/dev/null

echo "== uci 关键项 =="
uci show openclash 2>/dev/null | sed -n '/config_path/p;/\.enable=/p;/core_version/p;/config_subscribe/p' | head -8

echo "== 订阅条目 =="
uci show openclash 2>/dev/null | grep -E 'config_subscribe|\.url=' | head -5
