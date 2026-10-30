#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/network_guide/network"
SETC=$(curl -s -i -m 20 -d "luci_username=root&luci_password=admin" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/details" | grep -i "^Set-Cookie:" | grep -o "sysauth=[0-9a-fA-F]*" | head -1)
echo "cookie=$SETC"
printf '  无Origin(curl):  '; curl -s -m 15 -H "Cookie: $SETC" -d "sim=2" "$B?action=sim_switch"; echo
printf '  sim=99:          '; curl -s -m 15 -H "Cookie: $SETC" -d "sim=99" "$B?action=sim_switch"; echo
printf '  sim=当前卡(2):   '; curl -s -m 15 -H "Cookie: $SETC" -d "sim=2" "$B?action=sim_switch"; echo
printf '  oc_sub ftp:      '; curl -s -m 15 -H "Cookie: $SETC" --data-urlencode "url=ftp://bad" "$B?action=oc_sub"; echo
printf '  跨源Origin:      '; curl -s -m 15 -H "Cookie: $SETC" -H "Origin: http://evil.example" -d "sim=2" "$B?action=sim_switch"; echo
printf '  同源Origin:      '; curl -s -m 15 -H "Cookie: $SETC" -H "Origin: http://192.168.66.1:8080" -d "sim=2" "$B?action=sim_switch"; echo
