#!/bin/sh
B=https://mirror.sjtu.edu.cn/openwrt/releases/23.05.5/packages/aarch64_cortex-a53/packages
curl -s -m 60 "$B/Packages.gz" -o /tmp/P.gz
echo "index size: $(wc -c < /tmp/P.gz)"
gunzip -c /tmp/P.gz 2>/dev/null | awk '
/^Package: (dockerd|containerd|runc|docker)$/ {p=$2}
/^Filename: / {if (p!="") {print p": "$2; p=""}}
' | head -10
