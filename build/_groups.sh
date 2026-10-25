#!/bin/sh
SEC=$(uci -q get openclash.config.dashboard_password)
PORT=$(uci -q get openclash.config.cn_port)
[ -n "$PORT" ] || PORT=9090
echo "secret=$SEC port=$PORT"

lua -e "
local jsonc = require('luci.jsonc')
local f = io.popen('curl -s -m 8 -H \"Authorization: Bearer $SEC\" http://127.0.0.1:$PORT/proxies')
local raw = f:read('*a'); f:close()
local t = jsonc.parse(raw)
if type(t) ~= 'table' or type(t.proxies) ~= 'table' then print('parse failed'); return end
local list = {}
for name, p in pairs(t.proxies) do
  if type(p) == 'table' and p.type == 'Selector' then
    list[#list+1] = { name = name, n = #(p.all or {}), now = tostring(p.now) }
  end
end
table.sort(list, function(a,b) return a.n > b.n end)
for i, g in ipairs(list) do
  print(string.format('  %-30s nodes=%-4d now=%s', g.name, g.n, g.now))
end
"
