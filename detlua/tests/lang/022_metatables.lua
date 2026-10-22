local V = {}
V.__index = V
V.__add = function(a, b) return V.new(a.x + b.x, a.y + b.y) end
V.__eq = function(a, b) return a.x == b.x and a.y == b.y end
V.__tostring = function(v) return "(" .. v.x .. "," .. v.y .. ")" end
function V.new(x, y) return setmetatable({x = x, y = y}, V) end
function V:len2() return self.x * self.x + self.y * self.y end

local a, b = V.new(1, 2), V.new(3, 4)
print(tostring(a + b))
print(a + b == V.new(4, 6))
print(b:len2())

local defaults = setmetatable({}, {__index = function(t, k) return k .. "!" end})
print(defaults.hey)

local proxy = setmetatable({}, {__newindex = function(t, k, v) rawset(t, k, v * 2) end})
proxy.a = 5
print(proxy.a)

local callable = setmetatable({}, {__call = function(self, x) return x + 1 end})
print(callable(41))
