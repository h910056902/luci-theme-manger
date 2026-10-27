#!/bin/sh
F=/overlay/apkdl/runc-1.3.6-r1.apk
echo "== 前 16 字节 =="
od -An -tx1 -N 16 "$F"
echo "== file 判断（若有）=="
file "$F" 2>/dev/null || echo "  无 file 命令"
echo "== gzip 尝试 =="
gunzip -t "$F" 2>&1 | head -2
echo "== tar 列出（不带 z）=="
tar -tf "$F" 2>&1 | head -5
echo "== 前 256 字节可打印 =="
head -c 256 "$F" | tr -c '[:print:]\n' '.' | head -5
