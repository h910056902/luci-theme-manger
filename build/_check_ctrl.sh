#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080

echo "== CGI 里 admin.nodes.docker 的上下文 =="
grep -n 'admin.nodes.docker' "$D/www/cgi-bin/luci" | head -3

echo "== controller 是否被 require 到 =="
lua -e "local ok,m=pcall(require,'luci.controller.kp_docker'); print('require:',ok,m); if ok then m.index(); print('index() 调用成功') end"

echo "== 缓存文件 =="
ls -l /tmp/luci-indexcache* 2>/dev/null | head -3
echo -n "缓存中 docker 关键字: "
grep -c 'docker' /tmp/luci-indexcache* 2>/dev/null | head -2

echo "== 直接看 dispatcher 树是否有 admin/docker =="
lua -e '
local d = require "luci.dispatcher"
local ok, err = pcall(function() d.createtree() end)
print("createtree:", ok, err or "")
local n = d.context and d.context.tree
if type(n) == "table" then
  local a = n.admin
  if a and a.nodes then
    for k,v in pairs(a.nodes) do
      if type(v)=="table" and v.title then print("  node:", k, v.title, v.order) end
    end
  end
end
' 2>&1 | head -20
