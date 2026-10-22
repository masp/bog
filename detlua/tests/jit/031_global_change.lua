-- A hot loop calling a global function that gets redefined mid-loop.
function f(x) return x + 1 end
local acc = 0
for i = 1, 200000 do
  if i == 100001 then f = function(x) return x - 1 end end
  acc = f(acc)
end
print(acc)
