#!/bin/sh
set -e
cd /build
echo "== extract =="
rm -rf linux-6.12.94
tar -xf linux-6.12.94.tar.xz
echo "== configure =="
cd linux-6.12.94
cp /build/config-vendor .config
make olddefconfig >/tmp/olddef.log 2>&1 || { echo "olddefconfig FAIL"; tail -20 /tmp/olddef.log; exit 1; }
grep -E '^CONFIG_LOCALVERSION=|^CONFIG_MODULES=|^CONFIG_SMP=' .config
echo "== modules_prepare =="
make -j2 modules_prepare >/tmp/mp.log 2>&1 || { echo "modules_prepare FAIL"; tail -30 /tmp/mp.log; exit 1; }
echo "== kernelrelease =="
make -s kernelrelease
echo "KERNEL_BUILD_OK"
