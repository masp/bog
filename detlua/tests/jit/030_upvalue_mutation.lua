-- A hot closure whose upvalue is changed from outside mid-run.
local step = 1
local function bump(x) return x + step end
local v = 0
for i = 1, 200000 do
  if i == 100000 then step = 10 end
  v = bump(v)
end
print(v)
