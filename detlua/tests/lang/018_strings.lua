local s = "Hello, Lua"
print(s:len(), #s)
print(s:upper(), s:lower())
print(s:sub(1, 5), s:sub(-3))
print(string.rep("ab", 3))
print(string.format("%d items at %s", 3, "noon"))
print(string.format("%5.2f|%-4s|%x", 3.14159, "x", 255))
print(("x"):byte(), string.char(65, 66))
print(s:find("Lua"))
print("a\tb\\n\"q\"")
print([[long
string]])
print(10 .. 20)
