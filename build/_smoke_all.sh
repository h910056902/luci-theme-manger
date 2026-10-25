#!/bin/sh
B=http://192.168.66.1:8080/cgi-bin/luci/admin/status
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
H="Cookie: sysauth=$SID"

hit() { # page action
	R=$(curl -s -m 20 -H "$H" "$B/$1?action=$2" 2>/dev/null | head -c 220)
	case "$R" in
		*'"code":0'*) echo "  OK   $2" ;;
		''|*login_required*) echo "  AUTH $2 -> $R" ;;
		*) echo "  FAIL $2 -> $R" ;;
	esac
}

echo "== 概览 =="
hit overview kp_status

echo "== 蜂窝（只读）=="
for a in poll stats cell neighbor devices simlock swap terminal hnat web_listen qos_list; do
	hit cellular "$a"
done

echo "== 短信 =="
hit sms sms_fwd_get

echo "== 写操作保护：无确认应被拒 =="
for a in swap hnat at_raw modem_reboot; do
	R=$(curl -s -m 20 -H "$H" -d "op=on" "$B/cellular?action=$a" | head -c 120)
	case "$R" in
		*'"code":1'*) echo "  GUARD $a -> $R" ;;
		*) echo "  LEAK  $a -> $R" ;;
	esac
done
echo DONE
