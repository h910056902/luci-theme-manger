#!/bin/sh
R=$(ubus call infocd runtime 2>/dev/null | grep -c sim_mon)
C=$(ubus call infocd cpestatus '{"name":"cpe"}' 2>/dev/null | grep -c sim_mon)
echo "runtime.sim_mon 出现次数: $R"
echo "cpestatus.sim_mon 出现次数: $C"
echo "--- runtime 里 cpe 数组的键 ---"
ubus call infocd runtime 2>/dev/null | tr ',' '\n' | grep -o '"[a-z_0-9]*":' | sort -u | head -30
