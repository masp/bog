-- Float-heavy hot loops.
local w, h, iters = 60, 24, 200
local inside = 0
for y = 0, h - 1 do
  local ci = (y / h) * 2.0 - 1.0
  local row = {}
  for x = 0, w - 1 do
    local cr = (x / w) * 3.0 - 2.0
    local zr, zi, n = 0.0, 0.0, 0
    while n < iters and zr * zr + zi * zi < 4.0 do
      zr, zi = zr * zr - zi * zi + cr, 2.0 * zr * zi + ci
      n = n + 1
    end
    if n == iters then inside = inside + 1; row[#row + 1] = "#" else row[#row + 1] = "." end
  end
  print(table.concat(row))
end
print(inside)
