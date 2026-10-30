#!/bin/sh
echo "===== 1. IPv6-only 绑定假设验证 ====="
echo "  net.ipv6.bindv6only = $(cat /proc/sys/net/ipv6/bindv6only 2>/dev/null)"
echo
echo "===== 2. IPv6 环回测试（若通则假设成立）====="
curl -s -m 8 -x "http://[::1]:7893" -o /dev/null -w "  [::1]:7893 -> %{http_code} (%{time_total}s)\n" https://www.gstatic.com/generate_204 2>&1
curl -s -m 8 -x "http://[::1]:7890" -o /dev/null -w "  [::1]:7890 -> %{http_code} (%{time_total}s)\n" https://www.gstatic.com/generate_204 2>&1
echo
echo "===== 3. 裸 TCP 连接测试（nc）====="
command -v nc >/dev/null && { echo "  nc 存在"; timeout 3 nc -z 127.0.0.1 7893 2>&1 && echo "  127.0.0.1:7893 TCP 可连" || echo "  127.0.0.1:7893 TCP 被拒"; } || echo "  无 nc"
echo
echo "===== 4. /proc/net/tcp vs tcp6 里的监听 ====="
echo "  v4 监听:"; grep -E ':1ED2|:1ED1|:1ED3|:1ED5' /proc/net/tcp 2>/dev/null | awk '{print "    " $2}' | head -4
echo "  v6 监听:"; grep -E ':1ED2|:1ED1|:1ED3|:1ED5' /proc/net/tcp6 2>/dev/null | awk '{print "    " $2}' | head -4
echo
echo "===== 5. LAN 真实流量验证（透明代理确实在工作）====="
tail -200 /tmp/openclash.log 2>/dev/null | grep -c '\[TCP\]'
echo "  ↑ 近 200 行日志中 LAN 流量条数"
echo
echo "===== 6. sysctl 持久化位置 ====="
ls /etc/sysctl.conf /etc/sysctl.d/ 2>/dev/null
grep -rn 'bindv6only' /etc/sysctl.conf /etc/sysctl.d/ /etc/openclash/ 2>/dev/null | head -3
