#!/bin/sh
echo "== manual uci =="
uci set kpnet.qos=globals
uci set kpnet.qos.enabled=1
uci set kpnet.qos.plan=1000000
uci set kpnet.dev_aa=dev
uci set kpnet.dev_aa.mac=aa:bb:cc:dd:ee:ff
uci commit kpnet
echo "rc=$?"
uci show kpnet
ls -l /etc/config/kpnet 2>/dev/null
echo "== via luci.sys.exec =="
lua -e 'local s=require"luci.sys"; print(s.exec("uci -q get kpnet.qos.enabled")); print(s.exec("uci set kpnet.qos.wan=eth3; uci commit kpnet; echo done"))'
uci -q get kpnet.qos.wan
echo "== cleanup =="
uci -q delete kpnet
uci commit kpnet
rm -f /etc/config/kpnet
echo done
