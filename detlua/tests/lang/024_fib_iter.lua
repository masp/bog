local function fib(n)
  local a, b = 0, 1
  for _ = 1, n do a, b = b, a + b end
  return a
end
for _, n in ipairs({0, 1, 2, 10, 50, 90}) do print(n, fib(n)) end
