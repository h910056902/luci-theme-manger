#!/bin/sh
at() {
    printf -- "--- %s\n" "$1"
    ubus call atsdcpe at_cmd "{\"cmd\":\"$1\",\"wait\":1500,\"at_log_level\":0,\"block\":1}" 2>&1 | tr -d '\r' | head -c 600
    echo
}
at "AT+CGNSSINFO?"
at "AT+CGNSSPWR?"
at "AT+CGPSINFO"
at "AT^GNSSINFO?"
at "AT+GPSLOC?"
at "AT+CGNSSMODE?"
echo "--- tty ---"
ls -l /dev/ttyUSB* 2>/dev/null
echo "--- nmea/gpsd ---"
pidof gpsd 2>/dev/null || echo "no gpsd"
ls /dev/ttyACM* 2>/dev/null
