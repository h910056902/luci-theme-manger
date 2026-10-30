-- 逐块检查两个模板的 <% %> Lua 语法（loadstring）
local files = {
	"/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/kp_sim_card.htm",
	"/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm",
}
local bad_total = 0
for _, path in ipairs(files) do
	local f = io.open(path, "r")
	if not f then
		print("MISSING " .. path)
		bad_total = bad_total + 1
	else
		local src = f:read("*a")
		f:close()
		local n, bad = 0, 0
		for code in src:gmatch("<%%(.-)%%>") do
			n = n + 1
			if not code:match("^=") and code:sub(1, 1) ~= "+" then
				local fn, err = loadstring(code, "blk" .. n)
				if not fn then
					bad = bad + 1
					print(path:match("[^/]+$") .. " 块" .. n .. " 错误: " .. tostring(err))
				end
			end
		end
		print(path:match("[^/]+$") .. " blocks=" .. n .. " bad=" .. bad)
		bad_total = bad_total + bad
	end
end
os.exit(bad_total > 0 and 1 or 0)
