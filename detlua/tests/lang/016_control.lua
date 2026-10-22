local i = 0
repeat
  i = i + 1
until i >= 5
print(i)

for j = 1, 10 do
  if j == 4 then break end
  print(j)
end

-- break only exits the innermost loop
for a = 1, 3 do
  for b = 1, 3 do
    if b == 2 then break end
    print(a, b)
  end
end

-- skip evens (no goto in 5.1)
for k = 1, 5 do
  if k % 2 ~= 0 then
    print("odd", k)
  end
end

-- zero-trip loop
for x = 1, 0 do print("never") end
print("end")
