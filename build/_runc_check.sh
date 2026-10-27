#!/bin/sh
echo "== runc =="
ls -l /usr/sbin/runc /usr/bin/runc 2>/dev/null
/usr/sbin/runc --version 2>&1 | head -3
echo "== 依赖 =="
ldd /usr/sbin/runc 2>/dev/null | grep -i 'not found' || echo "  库齐全"
echo "== containerd 是否认识 runc =="
command -v runc || echo "  PATH 中没有 runc（PATH=$PATH）"
echo "== containerd 配置 =="
grep -rn 'runtime' /etc/containerd/config.toml 2>/dev/null | head -5 || echo "  无 config.toml"
echo "== containerd 进程 =="
ps w | grep '[c]ontainerd' | head -2
echo "== 手工跑 runc =="
/usr/sbin/runc --help >/dev/null 2>&1 && echo "  runc 可执行" || echo "  runc 无法执行 rc=$?"
