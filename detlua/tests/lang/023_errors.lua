local ok, err = pcall(function() error("boom", 0) end)
print(ok, err)

ok, err = pcall(function() error({code = 7}) end)
print(ok, err.code)

ok, err = pcall(function() local t = nil; return t.x end)
print(ok)

print(pcall(function(a, b) return a + b end, 2, 3))

print(select(2, pcall(error, "plain", 0)))
