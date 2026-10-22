-- A branch that is never taken during warmup, then taken often.
local evens, odds, big = 0, 0, 0
for i = 1, 300000 do
  if i > 250000 then
    big = big + 1
  elseif i % 2 == 0 then
    evens = evens + 1
  else
    odds = odds + 1
  end
end
print(evens, odds, big)
