local path = arg[1]
local f, e = loadfile(path)
if f then
  print("LUA_OK " .. path)
else
  print("LUA_ERR " .. tostring(e))
end
