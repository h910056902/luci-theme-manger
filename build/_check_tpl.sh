#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_term.htm
lua - "$F" <<'LUA'
local path = arg[1]
local src = io.open(path, "r"):read("*a")

-- 1) 逐块检查 <% %> 的 Lua 语法
local n, bad = 0, 0
for code in src:gmatch("<%%(.-)%%>") do
	n = n + 1
	if not code:match("^=") and code:sub(1, 1) ~= "+" then
		local f, err = loadstring(code, "block" .. n)
		if not f then
			bad = bad + 1
			print(string.format("块%d 语法错误: %s", n, err))
		end
	end
end
print(string.format("Lua 块: %d 个，错误 %d 个", n, bad))

-- 2) 关键结构
local function has(p) return src:find(p, 1, true) and "有" or "缺" end
print("kpt-bar      :", has('class="kpt-bar"'))
print("kpt-dot      :", has('id="kpt-dot"'))
print("kpt-term     :", has('id="kpt-term"'))
print("kpt-clear    :", has('id="kpt-clear"'))
print("xterm-screen :", has('.xterm-screen'))
print("Terminal(    :", has('new Terminal('))
print("WebSocket    :", has('new WebSocket'))
print("footer       :", has('<%+footer%>'))

-- 3) 样式块数量与顺序
local s1 = src:find('<style type="text/css">', 1, true)
local s2 = src:find('class="kpt"', 1, true)
print(string.format("首个 style 位置 %d，卡片位置 %d（应 style 在前）", s1 or -1, s2 or -1))
LUA
