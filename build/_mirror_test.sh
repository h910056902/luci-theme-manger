#!/bin/sh
U=https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz
for m in "https://ghproxy.net" "https://mirror.ghproxy.com" "https://gh-proxy.com" "https://ghfast.top" "https://gh.llkk.cc"; do
	code=$(curl -sL -m 25 -o /dev/null -w '%{http_code}' -r 0-2047 "$m/$U" 2>/dev/null)
	echo "  $m -> $code"
done
