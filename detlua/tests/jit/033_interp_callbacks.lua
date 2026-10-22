-- Compiled code calling builtins and Lua callbacks that call back in.
local t = {}
for i = 1, 2000 do t[i] = (i * 7919) % 2003 end
table.sort(t, function(a, b) return a < b end)
print(t[1], t[1000], t[2000])

local parts = {}
for i = 1, 20000 do parts[#parts + 1] = tostring(i % 10) end
local str = table.concat(parts)
print(#str, str:sub(1, 12))

local ok_count = 0
for i = 1, 20000 do
  local ok = pcall(function() if i % 1000 == 0 then error("x") end end)
  if ok then ok_count = ok_count + 1 end
end
print(ok_count)
