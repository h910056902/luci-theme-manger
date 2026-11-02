#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
echo "==SYMLINKS=="
find $D -type l 2>/dev/null | while read p; do echo "$p|$(readlink "$p")"; done
echo "==FILES-MD5=="
cd $D || exit 1
find . -type f 2>/dev/null | sed 's#^\./##' | sort | xargs md5sum 2>/dev/null
