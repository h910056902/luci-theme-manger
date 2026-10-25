#!/bin/sh
B=http://192.168.66.1:8080/cgi-bin/luci/admin/status
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
H="Cookie: sysauth=$SID"

hit() {
	BODY=$(curl -s -m 25 -H "$H" "$B/$1?action=$2" 2>/dev/null)
	LEN=$(printf '%s' "$BODY" | wc -c)
	if printf '%s' "$BODY" | grep -q '"code":0'; then
		echo "  OK    $2 (${LEN}B)"
	elif printf '%s' "$BODY" | grep -q 'login_required'; then
		echo "  AUTH  $2"
	elif [ "$LEN" -lt 2 ]; then
		echo "  EMPTY $2"
	else
		echo "  ?     $2 (${LEN}B) $(printf '%s' "$BODY" | head -c 100)"
	fi
}

echo "== 只读接口（全文匹配 code:0）=="
hit overview kp_status
for a in poll stats cell neighbor devices simlock swap terminal hnat web_listen; do
	hit cellular "$a"
done
hit sms sms_fwd_get
echo DONE
