local path = arg[1]
local p = require "luci.template.parser"
local f = assert(io.open(path, "rb"))
local s = f:read("*a")
f:close()
local t, a, b = p.parse_string(s)
if t then
  print("TPL_OK   " .. path)
else
  print("TPL_ERR  " .. path .. " :: " .. tostring(b))
end
