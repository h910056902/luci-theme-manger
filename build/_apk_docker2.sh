#!/bin/sh
echo "== apk 相关开关 =="
apk add --help 2>&1 | grep -iE 'broken|untrusted|virtual' | head -6

echo "== 先试 force-broken-world =="
if apk add --help 2>&1 | grep -qi 'force-broken-world'; then
	apk add --no-progress --force-broken-world docker dockerd containerd runc 2>&1 | tail -10
else
	echo "  该 apk 版本无此开关"
fi

echo "== 结果 =="
command -v dockerd && dockerd --version || echo "  仍未安装"
