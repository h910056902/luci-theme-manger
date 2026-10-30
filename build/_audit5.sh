#!/bin/sh
echo "===== 1. 安全暴露面 ====="
echo "-- 开机自启的可疑服务 --"
for s in telnetd fwdd wifidogx miniupnpd atserver-sniffer terminal_trackd wanchk combo report_proactively autotimeset; do
  printf "  %-22s " "$s"; pgrep -f "$s" >/dev/null 2>&1 && echo "运行中" || echo "未运行"
done
echo "-- 对外监听端口（0.0.0.0/::）--"
netstat -lnp 2>/dev/null | grep -E '0\.0\.0\.0|:::' | awk '{print $4, $6, $7}' | sort -u | head -20
echo "-- WAN 侧入站规则（防火墙）--"
uci show firewall 2>/dev/null | grep -iE 'input.*(ACCEPT|allow)' | head -5
nft list chain inet fw4 input_wan 2>/dev/null | head -8
echo "-- ssh/telnet 配置 --"
grep -E 'Port|PasswordAuth|PermitRoot' /etc/config/dropbear 2>/dev/null | head -5
uci get dropbear.@dropbear[0].PasswordAuth 2>/dev/null
echo
echo "===== 2. 开机/内核错误 ====="
dmesg 2>/dev/null | grep -iE 'error|fail|warn|oops|panic' | tail -10
echo "-- logread 近期错误 --"
logread 2>/dev/null | grep -iE 'error|fail|crit' | tail -10
echo
echo "===== 3. Docker 容器健康 ====="
echo "-- 容器与重启策略 --"
ls /overlay/docker/containers/ 2>/dev/null | while read -r id; do
  name=$(grep -o '"Name":"[^"]*"' /overlay/docker/containers/$id/config.v2.json 2>/dev/null | head -1)
  rp=$(grep -o '"RestartPolicy":{"Name":"[^"]*"' /overlay/docker/containers/$id/config.v2.json 2>/dev/null | sed 's/.*Name":"//')
  echo "  ${name:-$id}  restart=$rp"
done
echo "-- 容器日志体积 --"
du -sh /overlay/docker/containers/*/  2>/dev/null | head -5
echo "-- dockerd 日志尾 --"
logread 2>/dev/null | grep -iE 'dockerd|containerd' | tail -5
echo
echo "===== 4. OpenClash 转发质量 ====="
echo "-- 代理连通性（经 7890 出网）--"
curl -s -m 12 -x http://127.0.0.1:7890 -o /dev/null -w "  google.com -> %{http_code} (%{time_total}s)\n" https://www.google.com 2>&1
curl -s -m 12 -o /dev/null -w "  本机直连 baidu -> %{http_code} (%{time_total}s)\n" https://www.baidu.com 2>&1
echo "-- DNS 劫持 --"
nslookup www.google.com 127.0.0.1 2>/dev/null | tail -4
echo "-- clash 日志近 5 条 --"
tail -5 /tmp/openclash.log 2>/dev/null
echo
echo "===== 5. 备份完整性（sysupgrade 会带哪些）===="
sysupgrade -l 2>/dev/null | grep -E 'app_store|veth|kp-|docker|swap' | head -10
echo
echo "===== 6. uci-defaults 脚本语法 ====="
sh -n /etc/uci-defaults/99-kp-post-upgrade 2>&1 && echo "  OK"
echo
echo "===== 7. 时间同步 ====="
date
pgrep -f ntpd >/dev/null 2>&1 && echo "  ntpd 运行中" || echo "  ntpd 未运行!"
echo
echo "===== 8. 磁盘/文件系统健康 ====="
dmesg 2>/dev/null | grep -iE 'mmc|EXT4|I/O error' | tail -5
echo "-- overlay 读写测试 --"
touch /overlay/.kp_rw_test 2>/dev/null && rm -f /overlay/.kp_rw_test && echo "  可写 OK"
echo
echo "===== 9. 内存 TOP ====="
ps w | awk '{print $6, $7}' | grep -v VSZ | sort -rn | head -8
echo
echo "===== 10. 系统资源总览 ====="
uptime
free -m
