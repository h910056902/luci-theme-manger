#!/bin/sh
tr -d '\r' < /tmp/_up_kpuboot > /usr/bin/kp-uboot
chmod 755 /usr/bin/kp-uboot
printf "  %7s  %s\n" "$(wc -c < /usr/bin/kp-uboot)" /usr/bin/kp-uboot

sh -n /usr/bin/kp-uboot && echo "  syntax OK"

echo
echo "===== status ====="
/usr/bin/kp-uboot status

echo
echo "===== caps（从 FIP 实测）====="
/usr/bin/kp-uboot caps

echo
echo "===== menu dry-run ====="
/usr/bin/kp-uboot menu | head -12
