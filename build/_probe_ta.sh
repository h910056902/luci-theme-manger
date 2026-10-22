#!/bin/sh
at() {
    echo "--- $1"
    ubus call atsdcpe at_cmd "{\"cmd\":\"$1\",\"wait\":1500,\"at_log_level\":0,\"block\":1}" 2>&1 | tr -d '\r' | head -c 700
    echo
}
at "AT+C5GREG=?"
at "AT^MONSC"
at "AT+CEREG=?"
at "AT^SYSINFOEX"
