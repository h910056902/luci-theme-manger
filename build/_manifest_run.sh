#!/bin/sh
sh /tmp/_manifest.sh > /tmp/manifest.txt 2>/tmp/manifest.err
echo "lines: $(wc -l < /tmp/manifest.txt)"
echo "errors: $(wc -l < /tmp/manifest.err)"
echo "--- 前 5 行 ---"
head -5 /tmp/manifest.txt
echo "--- 错误 ---"
head -5 /tmp/manifest.err
