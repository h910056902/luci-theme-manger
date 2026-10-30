#!/bin/sh
# Final deploy for Docker bridge unlock: docker page text, veth persistence, DNS bypass rules.
set -u

echo "===== 1. Docker 页面提示文案 ====="
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_docker.htm
if [ -f "$F" ] && [ -f /tmp/kp_nradio_docker.htm ]; then
	cp -f "$F" "$F.kp-hostonly.bak" 2>/dev/null
	cp -f /tmp/kp_nradio_docker.htm "$F"
	chmod 644 "$F"
	echo "  patched: $(grep -c '自编译 <strong>veth' "$F") 处"
	grep -n '自编译' "$F" | head -3
else
	echo "  SKIP (file missing)"
fi

echo
echo "===== 2. persist veth module (init script) ====="
sh /tmp/persist_veth.sh 2>&1 | tail -20

echo
echo "===== 3. DNS bypass rules for docker0 ====="
# 3a. OpenClash 自定义防火墙钩子（OpenClash 的 53 劫持规则之后执行）
H=/etc/openclash/custom/openclash_custom_firewall_rules.sh
if [ -f "$H" ]; then
	cp -f "$H" "$H.kp-bak" 2>/dev/null
	cat > "$H" <<'EOF'
#!/bin/sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

# This script is called by /etc/init.d/openclash
# Add your custom firewall rules here, they will be added after the end of the OpenClash iptables rules

LOG_TIP "Start Add Custom Firewall Rules..."

# KP-DOCKER-DNS: docker0 容器 DNS 绕开 OpenClash 的 53 劫持（容器 DNS=223.5.5.5/119.29.29.29）
iptables -t nat -C PREROUTING -i docker0 -p udp --dport 53 -j RETURN 2>/dev/null || iptables -t nat -I PREROUTING 1 -i docker0 -p udp --dport 53 -j RETURN
iptables -t nat -C PREROUTING -i docker0 -p tcp --dport 53 -j RETURN 2>/dev/null || iptables -t nat -I PREROUTING 1 -i docker0 -p tcp --dport 53 -j RETURN

exit 0
EOF
	chmod 755 "$H"
	echo "  openclash hook: updated"
fi

# 3b. firewall.user（每次 fw3 reload 时执行）
FU=/etc/firewall.user
if ! grep -q 'KP-DOCKER-DNS' "$FU" 2>/dev/null; then
	cp -f "$FU" "$FU.kp-bak" 2>/dev/null
	BLOCK='
# KP-DOCKER-DNS: docker0 容器 DNS 绕开 OpenClash 的 53 劫持（容器 DNS=223.5.5.5/119.29.29.29）
iptables -t nat -C PREROUTING -i docker0 -p udp --dport 53 -j RETURN 2>/dev/null || iptables -t nat -I PREROUTING 1 -i docker0 -p udp --dport 53 -j RETURN
iptables -t nat -C PREROUTING -i docker0 -p tcp --dport 53 -j RETURN 2>/dev/null || iptables -t nat -I PREROUTING 1 -i docker0 -p tcp --dport 53 -j RETURN
'
	if command -v iptables-legacy >/dev/null 2>&1; then
		printf '%s\n' "$BLOCK" >> "$FU"
		echo "  firewall.user: appended"
	else
		# 文件开头有 iptables-legacy 缺失时 exit 的逻辑，插到最前面
		printf '%s\n' "$BLOCK" | cat - "$FU" > "$FU.tmp" && mv "$FU.tmp" "$FU"
		echo "  firewall.user: prepended"
	fi
fi

# 3c. 立即生效（幂等）
iptables -t nat -C PREROUTING -i docker0 -p udp --dport 53 -j RETURN 2>/dev/null || iptables -t nat -I PREROUTING 1 -i docker0 -p udp --dport 53 -j RETURN
iptables -t nat -C PREROUTING -i docker0 -p tcp --dport 53 -j RETURN 2>/dev/null || iptables -t nat -I PREROUTING 1 -i docker0 -p tcp --dport 53 -j RETURN

echo
echo "===== 4. 校验 ====="
echo "-- veth module --"
ls -l /lib/modules/$(uname -r)/veth.ko /etc/init.d/kp-veth 2>/dev/null
ls -l /etc/rc.d/ | grep kp-veth
echo "-- dns bypass rules --"
iptables -t nat -S PREROUTING | head -4
echo "-- docker bridge --"
docker network ls 2>/dev/null
echo "-- docker daemon config --"
cat /etc/docker/daemon.json
echo "DEPLOY_FINAL_DONE"
