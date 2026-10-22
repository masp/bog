local n = 5
if n > 3 then print("big") else print("small") end
if n == 1 then
  print("one")
elseif n == 5 then
  print("five")
else
  print("other")
end
if nil then print("nil is truthy?!") end
if 0 then print("0 is truthy") end
print(1 < 2, 2 <= 2, 3 ~= 3, "a" == "a")
