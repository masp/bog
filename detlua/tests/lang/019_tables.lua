local t = {1, 2, 3}
t[#t + 1] = 4
print(#t)
table.insert(t, 5)
table.insert(t, 1, 0)
print(table.concat(t, ","))
print(table.remove(t), table.concat(t, ","))

local nested = {a = {b = {c = "deep"}}}
print(nested.a.b.c)

local mixed = {"x", "y", key = "v", [10] = "ten"}
print(mixed[1], mixed[2], mixed.key, mixed[10])

-- ipairs stops at first nil
local n = 0
for i, v in ipairs({1, 2, nil, 4}) do n = n + 1 end
print(n)

-- pairs order is unspecified: aggregate instead of printing in order
local sum, cnt = 0, 0
for k, v in pairs({a = 1, b = 2, c = 3, 4}) do sum = sum + v; cnt = cnt + 1 end
print(sum, cnt)

local keys = {}
for k in pairs({z = 1, a = 1, m = 1}) do keys[#keys + 1] = k end
table.sort(keys)
print(table.concat(keys, " "))

local s = {5, 2, 8, 1}
table.sort(s, function(a, b) return a > b end)
print(table.concat(s, " "))
