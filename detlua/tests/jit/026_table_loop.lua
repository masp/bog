-- Array writes/reads in hot loops, including growth past the initial size.
local t = {}
for i = 1, 100000 do t[i] = i * 2 end
local s = 0
for i = 1, #t do s = s + t[i] end
print(#t, s)

-- Hash-part access in a hot loop
local h = {count = 0}
for i = 1, 100000 do h.count = h.count + 1 end
print(h.count)

-- Sieve of Eratosthenes
local N = 100000
local composite = {}
local primes = 0
for i = 2, N do
  if not composite[i] then
    primes = primes + 1
    for j = i * i, N, i do composite[j] = true end
  end
end
print(primes)
