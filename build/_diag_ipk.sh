#!/bin/sh
mk_ipk() { # $1=workdir $2=out
	cd "$1" || return 1
	echo 2.0 > debian-binary
	tar -C control -czf control.tar.gz .
	tar -C data -czf data.tar.gz .
	tar -czf "$2" debian-binary control.tar.gz data.tar.gz
	cd / || true
}

mk_control() { # $1=dir $2=ver
	mkdir -p "$1"
	cat > "$1/control" <<EOF
Package: kp-bk-test
Version: $2
Architecture: all
Maintainer: test
Section: utils
Priority: optional
Description: test
EOF
	cat > "$1/postinst" <<'EOF'
#!/bin/sh
echo "postinst ran"
exit 0
EOF
	chmod 755 "$1/postinst"
}

echo "=== 用例 A：极简包（几百字节）==="
rm -rf /tmp/tA && mkdir -p /tmp/tA/data/etc/kp-tA
echo hello > /tmp/tA/data/etc/kp-tA/a.txt
mk_control /tmp/tA/control 1.0
mk_ipk /tmp/tA /tmp/kp-tA.ipk
ls -lh /tmp/kp-tA.ipk
opkg install --force-reinstall /tmp/kp-tA.ipk 2>&1 | tail -5
echo -n "登记: "; opkg list-installed 2>/dev/null | grep -c kp-bk-test
opkg remove kp-bk-test >/dev/null 2>&1

echo
echo "=== 用例 B：带 5MB 载荷 ==="
rm -rf /tmp/tB && mkdir -p /tmp/tB/data/etc/kp-tB
dd if=/dev/urandom of=/tmp/tB/data/etc/kp-tB/blob bs=1M count=5 2>/dev/null
mk_control /tmp/tB/control 1.1
mk_ipk /tmp/tB /tmp/kp-tB.ipk
ls -lh /tmp/kp-tB.ipk
opkg install --force-reinstall /tmp/kp-tB.ipk 2>&1 | tail -5
echo -n "登记: "; opkg list-installed 2>/dev/null | grep -c kp-bk-test
opkg remove kp-bk-test >/dev/null 2>&1

echo
echo "=== 用例 C：带真实配置备份（14MB）==="
rm -rf /tmp/tC && mkdir -p /tmp/tC/data/etc/kp-tC
sysupgrade -k -b /tmp/tC/data/etc/kp-tC/config.tar.gz >/dev/null 2>&1
ls -lh /tmp/tC/data/etc/kp-tC/config.tar.gz
mk_control /tmp/tC/control 1.2
mk_ipk /tmp/tC /tmp/kp-tC.ipk
ls -lh /tmp/kp-tC.ipk
opkg install --force-reinstall /tmp/kp-tC.ipk 2>&1 | tail -5
echo -n "登记: "; opkg list-installed 2>/dev/null | grep -c kp-bk-test
rm -rf /tmp/tA /tmp/tB /tmp/tC /tmp/kp-tA.ipk /tmp/kp-tB.ipk
echo DONE
