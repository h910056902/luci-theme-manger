#!/bin/sh
echo "== 测试 GitHub API 可达性 =="
curl -s -m 10 -o /tmp/gh.json -w "api=%{http_code}\n" https://api.github.com/repos/MetaCubeX/mihomo/releases/latest
if [ -s /tmp/gh.json ]; then
	grep -o '"tag_name": *"[^"]*"' /tmp/gh.json | head -1
	grep -o 'https://[^"]*linux-arm64[^"]*' /tmp/gh.json | head -3
fi

echo "== OpenClash 自带核心下载脚本 =="
ls -l /usr/share/openclash/openclash_core.sh 2>/dev/null
grep -n 'core_version\|download\|github' /usr/share/openclash/openclash_core.sh 2>/dev/null | head -8
