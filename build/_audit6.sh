#!/bin/sh
echo "===== 1. 代理端口逐一测试 ====="
for p in 7890 7891 7892; do
  curl -s -m 8 -x "http://127.0.0.1:$p" -o /dev/null -w "  127.0.0.1:$p -> %{http_code} (%{time_total}s)\n" https://www.gstatic.com/generate_204 2>&1
  curl -s -m 8 -x "http://192.168.66.1:$p" -o /dev/null -w "  192.168.66.1:$p -> %{http_code} (%{time_total}s)\n" https://www.gstatic.com/generate_204 2>&1
done
echo "-- 端口绑定明细 --"
netstat -lnp 2>/dev/null | grep -E ':789[012]|:9090' 
echo "-- clash 监听配置 --"
grep -E 'mixed-port|port:|socks-port|bind-address|allow-lan|external-controller' /etc/openclash/*.yaml 2>/dev/null | grep -v '^#' | head -10
echo
echo "===== 2. 防火墙区域与 WAN ====="
uci show firewall 2>/dev/null | grep -E 'firewall\.@zone|firewall\.zone|\.network=' | head -20
echo "-- wan 口 IP --"
ubus call network.interface.wan status 2>/dev/null | grep -E '"address"|"up"' | head -3
ip -4 addr show pppoe-wan 2>/dev/null | grep inet
ip -4 addr show eth3 2>/dev/null | grep inet
echo "-- WAN 接口是哪个 --"
ubus call network.interface.wan status 2>/dev/null | grep -o '"device":"[^"]*"'
echo
echo "===== 3. ntp 配置 ====="
uci show system 2>/dev/null | grep -iE 'ntp|timezone' | head -8
pgrep -f 'busybox.*ntpd\|sysntpd' >/dev/null && echo "sysntpd 在跑" || echo "sysntpd 未跑"
ls -l /etc/rc.d/ | grep -iE 'ntp|sysntpd'
echo
echo "===== 4. Docker 重启策略修复预检 ====="
for c in dufs transmission; do
  id=$(ls /overlay/docker/containers/ | head -20 | while read -r i; do
    grep -q "\"Name\":\"/$c\"" /overlay/docker/containers/$i/config.v2.json 2>/dev/null && echo $i && break
  done)
  echo "  $c -> $id"
done
echo "-- docker 命令行试一下 --"
docker ps --format '{{.Names}}\t{{.Status}}' 2>&1 | head -5
docker inspect -f '{{.Name}} restart={{.HostConfig.RestartPolicy.Name}}' $(docker ps -q) 2>&1 | head -5
echo
echo "===== 5. DNS 再测 ====="
nslookup www.baidu.com 127.0.0.1 2>&1 | tail -5
nslookup www.google.com 127.0.0.1 2>&1 | tail -5
echo "-- dnsmasq 配置关键项 --"
uci show dhcp 2>/dev/null | grep -iE 'localservice|noresolv|server|port' | head -8
echo
echo "===== 6. mosquitto / kpcped / kpshd 鉴权 ====="
uci show mosquitto 2>/dev/null | head -10
grep -rn 'allow_anonymous\|password_file' /etc/mosquitto/ 2>/dev/null | head -4
echo
echo "===== 7. f2fs 工具可用性（swapfile 对齐修复用）===="
command -v fallocate && echo "  fallocate 可用" || echo "  fallocate 不可用"
command -v f2fs_io && echo "  f2fs_io 可用" || echo "  f2fs_io 不可用"
apk info 2>/dev/null | grep -E '^f2fs' | head -3
