local function two() return 1, 2 end
local a, b, c = two()
print(a, b, c)
print(two())
print(two(), 10)       -- truncated to one value when not last
print((two()))         -- parens truncate

local function count(...) return select("#", ...) end
print(count(), count(nil), count(1, nil, 3))

local function sum(...)
  local s = 0
  for _, v in ipairs({...}) do s = s + v end
  return s
end
print(sum(1, 2, 3, 4))

local function pass(...) return ... end
print(pass("x", "y"))
