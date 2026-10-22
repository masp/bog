-- Loop becomes hot with integral values, then the value becomes fractional.
local x = 0
for i = 1, 200000 do
  if i == 150000 then x = x + 0.5 end
  x = x + 1
end
print(x, x == math.floor(x))

-- Function specialised on integral numbers, later called with floats and strings.
local function add(a, b) return a + b end
local s = 0
for i = 1, 100000 do s = add(s, 1) end
print(s, add(1.5, 2), add("10", 5))
