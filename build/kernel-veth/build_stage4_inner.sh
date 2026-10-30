#!/bin/sh
set -e
cd /build/linux-6.12.94

echo "== 1. Kconfig: give WIRELESS_EXT default y (vendor kernel has it =y) =="
if ! grep -q 'default y' net/wireless/Kconfig; then
  sed -i 's/^config WIRELESS_EXT$/config WIRELESS_EXT\n\tdefault y/' net/wireless/Kconfig
fi
sed -n '1,6p' net/wireless/Kconfig

echo "== 2. apply CFG80211_HEADERS patch (ieee80211_ptr in net_device) =="
patch -p1 --no-backup-if-mismatch < /build/owrt-patches/731-cfg80211-headers.patch || echo "PATCH731_APPLY_FAILED"
grep -n 'CFG80211_HEADERS' include/linux/netdevice.h net/wireless/Kconfig | head -5

echo "== 3. restore vendor config + olddefconfig =="
cp /build/config-vendor .config
make olddefconfig >/tmp/olddef2.log 2>&1 || { tail -10 /tmp/olddef2.log; exit 1; }
echo "-- key config values --"
grep -E 'CONFIG_WIRELESS_EXT|CONFIG_CFG80211_HEADERS|CONFIG_CFG80211=|CONFIG_MODVERSIONS|CONFIG_MODULE_SIG|CONFIG_ETHERNET_PACKET_MANGLE' .config || true
echo "-- autoconf.h --"
grep -E 'CONFIG_WIRELESS_EXT|CONFIG_CFG80211_HEADERS' include/generated/autoconf.h 2>/dev/null | head -5

echo "== 4. modules_prepare =="
make -j2 modules_prepare >/tmp/mp2.log 2>&1 || { echo "modules_prepare FAIL"; tail -25 /tmp/mp2.log; exit 1; }
grep -E 'CONFIG_WIRELESS_EXT|CONFIG_CFG80211_HEADERS' include/generated/autoconf.h | head -5
echo "kernelrelease: $(make -s kernelrelease)"

echo "== 5. build veth.ko with ABI-matched headers =="
rm -rf /build/mod; mkdir -p /build/mod
cp drivers/net/veth.c /build/mod/veth.c
printf 'obj-m := veth.o\n' > /build/mod/Makefile
cd /build/mod
make -C /build/linux-6.12.94 M=/build/mod ARCH=arm64 KBUILD_MODPOST_WARN=1 modules 2>&1 | tail -6
ls -l /build/mod/veth.ko
strings /build/mod/veth.ko | grep -E '^vermagic=' | head -1
size -A /build/mod/veth.ko | grep -E 'this_module' || true
echo "ABI_FIX_BUILD_OK"
