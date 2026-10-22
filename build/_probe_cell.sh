#!/bin/sh
# 只读探测：蜂窝模块当前状态 + 可用的 AT 查询能力
echo "=== cpestatus ==="
ubus call infocd cpestatus '{"name":"cpe"}' 2>&1 | head -c 2600
echo
echo "=== runtime ==="
ubus call infocd runtime 2>&1 | head -c 800
echo
echo "=== AT 能力探测 ==="
at() {
    echo "--- $1"
    ubus call atsdcpe at_cmd "{\"cmd\":\"$1\",\"wait\":1500,\"at_log_level\":0,\"block\":1}" 2>&1 | tr -d '\r' | head -c 900
    echo
}
at "AT+CSQ"
at "AT^SYSINFOEX"
at "AT+CEREG?"
at "AT+C5GREG?"
at "AT^MONNC"
at "AT^HCSQ?"
at "AT^CAINFO?"
at "AT^NRSTATUS?"
at "AT^CELLINFO?"
at "AT^UECAPA?"
