-- First JIT target for functions: a small function called many times.
local function sq(x) return x * x end
local acc = 0
for i = 1, 100000 do
  acc = acc + sq(i % 100)
end
print(acc)
