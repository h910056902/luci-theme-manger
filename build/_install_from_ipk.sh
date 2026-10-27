#!/bin/sh
LOG=/overlay/ipk.log
ST=/overlay/ipk.state
: > "$LOG"
B=https://mirror.sjtu.edu.cn/openwrt/releases/23.05.5/packages/aarch64_cortex-a53/packages
W=/overlay/ipkdl
X=/overlay/ipkx
mkdir -p "$W" "$X"

echo download > "$ST"
for f in runc_1.1.14-1_aarch64_cortex-a53.ipk \
         containerd_1.7.22-1_aarch64_cortex-a53.ipk \
         dockerd_27.3.1-1_aarch64_cortex-a53.ipk \
         docker_27.3.1-1_aarch64_cortex-a53.ipk; do
	n=0
	while [ $n -lt 6 ]; do
		n=$((n+1))
		curl -sL -C - -m 150 -o "$W/$f" "$B/$f" 2>>"$LOG"
		sz=$(wc -c < "$W/$f" 2>/dev/null || echo 0)
		echo "  $f try$n size=$sz" >> "$LOG"
		[ "$sz" -gt 1000000 ] && break
	done
done

echo extract > "$ST"
cd "$X" || exit 1
for f in "$W"/*.ipk; do
	[ -f "$f" ] || continue
	tar -xzf "$f" ./data.tar.gz 2>>"$LOG" && tar -xzf ./data.tar.gz -C "$X" 2>>"$LOG" \
		&& echo "  OK $(basename "$f")" >> "$LOG" \
		|| echo "  FAIL $(basename "$f")" >> "$LOG"
done

echo copy > "$ST"
cp -a "$X"/. / 2>>"$LOG"
chmod 755 /usr/bin/dockerd /usr/bin/containerd /usr/bin/runc /usr/bin/docker 2>/dev/null
chmod 755 /etc/init.d/dockerd 2>/dev/null
chmod 755 /usr/bin/docker-init /usr/bin/docker-proxy /usr/bin/containerd-shim-runc-v2 2>/dev/null

echo verify > "$ST"
{ command -v dockerd; dockerd --version; docker --version; containerd --version; } >> "$LOG" 2>&1
echo done > "$ST"
