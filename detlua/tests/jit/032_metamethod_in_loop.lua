-- Hot loop where the operand type changes from number to a table with __add.
local mt = {__add = function(a, b) return (type(a) == "table" and a.v or a) + (type(b) == "table" and b.v or b) end}
local boxed = setmetatable({v = 3}, mt)
local s = 0
for i = 1, 100000 do
  local rhs = (i % 1000 == 0) and boxed or 1
  s = s + rhs
end
print(s)
