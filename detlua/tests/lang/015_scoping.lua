local x = 1
do
  local x = 2
  print(x)
end
print(x)

g = "global"
local function readg() return g end
print(readg())
g = "changed"
print(readg())

local function shadow(x)
  local x = x * 10
  return x
end
print(shadow(3), x)
