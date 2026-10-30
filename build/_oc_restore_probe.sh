#!/bin/sh
echo "== 1. 设备到 GitHub 的连通性 =="
wget -q --timeout=12 -O /tmp/_kp_probe.sh "https://raw.githubusercontent.com/h910056902/nros-panel/main/kp-ocspeed.sh" && echo "wget raw OK $(wc -c < /tmp/_kp_probe.sh) bytes" || echo "wget raw FAIL"
curl -s -m 12 -o /dev/null -w "curl raw: %{http_code}\n" "https://raw.githubusercontent.com/h910056902/nros-panel/main/kp-ocspeed.sh"
echo
echo "== 2. 当前 Clash 策略组名（选最快节点的目标组） =="
grep -E '^\s*-\s*name:' /etc/openclash/e_bbydy.yaml 2>/dev/null | head -8
echo "-- proxy-groups 段 --"
awk '/^proxy-groups:/{f=1;next} /^[a-z-]+:/{f=0} f&&/name:/{print}' /etc/openclash/e_bbydy.yaml 2>/dev/null | head -10
echo
echo "== 3. mihomo 控制口与密钥（ocspeed 用） =="
uci -q get openclash.config.cn_port; uci -q get openclash.config.dashboard_password
echo
echo "== 4. 数据盘 / 备份目录 =="
df -k /mnt/storage/data 2>/dev/null | tail -1 || echo "  无 /mnt/storage/data"
ls -d /mnt/storage/data/ocspeed-backup 2>/dev/null || echo "  无备份目录"
echo
echo "== 5. 历史数据是否还在（恢复后可直接沿用） =="
ls -la /etc/openclash-helper/ 2>/dev/null | head -8 || echo "  无 /etc/openclash-helper"
echo
echo "== 6. 菜单图标是否还在（仓库有 icon） =="
ls -l /usr/lib/lua/luci/view/ocspeed.htm /www/luci-static/nradio/images/icon/ocspeed.png 2>/dev/null || true
echo
echo "== 7. cron 现状 =="
crontab -l 2>/dev/null | grep -c ocspeed
