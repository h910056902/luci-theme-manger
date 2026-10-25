#!/bin/sh
mk() { # $1=名字 $2=control 文件内容来源
	W=/tmp/d_$1
	rm -rf "$W"; mkdir -p "$W/control" "$W/data/etc/d_$1"
	echo "x" > "$W/data/etc/d_$1/f.txt"
	cp "$2" "$W/control/control"
	printf '#!/bin/sh\necho postinst_%s\nexit 0\n' "$1" > "$W/control/postinst"
	chmod 755 "$W/control/postinst"
	( cd "$W" && echo 2.0 > debian-binary && tar -C control -czf control.tar.gz . && \
	  tar -C data -czf data.tar.gz . && tar -czf /tmp/d_$1.ipk debian-binary control.tar.gz data.tar.gz )
}

try() {
	echo "--- $1 ---"
	opkg install --force-reinstall "/tmp/d_$1.ipk" 2>&1 | tail -4
	echo -n "  登记: "; opkg list-installed 2>/dev/null | grep -c "^d_$1"
	opkg remove "d_$1" >/dev/null 2>&1
}

# D1: 带空 Depends
cat > /tmp/c1 <<'EOF'
Package: d_d1
Version: 1.0
Architecture: all
Maintainer: t
Section: utils
Priority: optional
Depends: 
Description: plain ascii
EOF

# D2: 中文 Description
cat > /tmp/c2 <<'EOF'
Package: d_d2
Version: 1.0
Architecture: all
Maintainer: t
Section: utils
Priority: optional
Description: 中文描述测试 恢复包
EOF

# D3: 无 Depends，有中文，控制脚本里带中文 echo
cat > /tmp/c3 <<'EOF'
Package: d_d3
Version: 1.0
Architecture: all
Maintainer: t
Section: utils
Priority: optional
Description: ascii only
EOF

mk d1 /tmp/c1
mk d2 /tmp/c2
mk d3 /tmp/c3

try d1
try d2
try d3

rm -rf /tmp/d_d1 /tmp/d_d2 /tmp/d_d3 /tmp/d_d1.ipk /tmp/d_d2.ipk /tmp/d_d3.ipk
echo DONE
