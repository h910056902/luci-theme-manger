#!/bin/sh
D=/overlay/kp-fw-backup/20261027-223109
cp "$D"/mtd4-*.bin /tmp/_fip.bin 2>/dev/null
cp "$D"/mtd0-*.bin /tmp/_bl2.bin 2>/dev/null
cp "$D"/mtd1-*.bin /tmp/_env.bin 2>/dev/null
ls -l /tmp/_fip.bin /tmp/_bl2.bin /tmp/_env.bin
echo "== FIP 头部 magic =="
head -c 32 /tmp/_fip.bin | cat -v | head -2
