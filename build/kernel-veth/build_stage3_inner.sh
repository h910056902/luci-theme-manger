#!/bin/sh
set -e
cd /build
echo "== copy veth.c =="
rm -rf mod
mkdir -p mod
cp linux-6.12.94/drivers/net/veth.c mod/veth.c
cat > mod/Makefile <<'EOF'
obj-m := veth.o
EOF
cd mod
echo "== build external module =="
make -C /build/linux-6.12.94 M=/build/mod ARCH=arm64 modules 2>&1 | tail -30
ls -l /build/mod/veth.ko
echo "== modinfo =="
strings /build/mod/veth.ko | grep -E '^vermagic=|^name=|^depends=|^license=' | head -5
echo "MODULE_BUILD_OK"
