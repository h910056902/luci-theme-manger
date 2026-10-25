#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
cd "$D" || exit 1
find . -type f 2>/dev/null \
	| grep -v '^./theme-backup' \
	| grep -v '\.bak' \
	| grep -v '\.kpbak' \
	| sort \
	| while read -r f; do
		printf '%s %s\n' "$(wc -c < "$f" 2>/dev/null)" "$f"
	done
