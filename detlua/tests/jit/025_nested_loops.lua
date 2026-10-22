local total = 0
for i = 1, 1000 do
  for j = 1, 1000 do
    total = total + (i * j + i) % 7
  end
end
print(total)
