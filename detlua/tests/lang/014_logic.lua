print(nil or "default")
print(false and error("not evaluated"))
print(1 and 2)
print(nil and 1)
print(false or nil)
print(not nil, not 0)
local calls = 0
local function hit() calls = calls + 1 return true end
local _ = true or hit()
local _ = false and hit()
print(calls)
