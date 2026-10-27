#!/bin/sh
rm -f /tmp/rc.ck
curl -s -c /tmp/rc.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://127.0.0.1/cgi-bin/luci/
echo "== 页面正文（去标签）=="
curl -s -b /tmp/rc.ck http://127.0.0.1/cgi-bin/luci/admin/system/recovery 2>/dev/null \
	| sed -e 's/<[^>]*>/ /g' | tr -s ' \n' ' ' | cut -c1-700
echo
echo "== 直接渲染模板看错误 =="
lua -e 'local t=require("luci.template"); local ok,err=pcall(function() t.render("kp_recovery/main") end); print("ok=",ok); print(err)'
echo "== 文件是否存在 =="
ls -l /usr/lib/lua/luci/view/kp_recovery/main.htm
