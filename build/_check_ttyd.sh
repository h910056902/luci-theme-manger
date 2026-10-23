#!/bin/sh
echo "== 版本 =="
/usr/bin/ttyd --version 2>&1 | head -2
echo "== 当前配置 =="
uci show ttyd 2>/dev/null
echo "== init 支持哪些选项 =="
grep -nE 'option|append_param|add_param' /etc/init.d/ttyd 2>/dev/null | head -25
echo "== 正在运行的参数 =="
ps w | grep '[t]tyd'
echo "== 主题文件 =="
ls -l /usr/share/ttyd 2>/dev/null || echo "无 /usr/share/ttyd"
