local t = {}
t[1] = "one"
t.x = 5
print(t[1], t.x, t.missing)
local arr = {10, 20, 30}
print(#arr, arr[2])
local p = {name = "bob", age = 3}
p.age = p.age + 1
print(p.name, p.age)
