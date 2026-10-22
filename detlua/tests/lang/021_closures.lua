local function counter()
  local n = 0
  return function()
    n = n + 1
    return n
  end
end
local c1, c2 = counter(), counter()
print(c1(), c1(), c1(), c2())

-- two closures sharing one upvalue
local function pair()
  local v = 0
  return function() v = v + 1 end, function() return v end
end
local inc, get = pair()
inc(); inc()
print(get())

-- fresh upvalue per loop iteration
local fns = {}
for i = 1, 3 do fns[i] = function() return i end end
print(fns[1](), fns[2](), fns[3]())
