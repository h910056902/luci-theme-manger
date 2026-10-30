#!/bin/sh
echo "===== 1. 透明代理用的哪套防火墙 ====="
iptables -t nat -S 2>/dev/null | grep -icE 'openclash|7892|7895' && echo "  (iptables 有 openclash 规则)" || true
nft list ruleset 2>/dev/null | grep -icE 'openclash' && echo "  (nft 有 openclash 规则)" || echo "  (nft 无 openclash 规则)"
echo
echo "===== 2. nat 表里的 openclash 链与跳转 ====="
iptables -t nat -S 2>/dev/null | grep -iE 'openclash|7892|7895|7893' | head -12
echo
echo "===== 3. OUTPUT 链（本机代理劫持路径）====="
iptables -t nat -S OPENCLASH 2>/dev/null | head -12
iptables -t nat -S OUTPUT 2>/dev/null | head -8
echo
echo "===== 4. mangle 表（TPROXY）====="
iptables -t mangle -S 2>/dev/null | grep -iE 'openclash|TPROXY|7895' | head -10
echo
echo "===== 5. curl -v 完整输出（确认拒绝层级）====="
curl -v -m 5 -x http://127.0.0.1:7893 https://www.gstatic.com/generate_204 2>&1 | tail -8
