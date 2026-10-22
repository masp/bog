JIT stress tests. Each program runs long enough that hot loops/functions should
get compiled, then does something that commonly breaks a naive JIT (type changes,
side exits, deopt, calls back into the interpreter). Output must be identical to
a pure interpreter.
