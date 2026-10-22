#!/usr/bin/env python3
"""Generate large deterministic Lua files for lexer benchmarks.

usage: gen_lexer_data.py OUT_DIR SIZE_MB
Writes OUT_DIR/<corpus>_<SIZE_MB>mb.lua for each corpus; existing files are kept.
"""
import glob, os, sys

def code(root):
    # Realistic code: the language and JIT test programs, concatenated.
    files = sorted(glob.glob(os.path.join(root, "tests/lang/*.lua")) + glob.glob(os.path.join(root, "tests/jit/*.lua")))
    return "".join(open(f).read() + "\n" for f in files)

def strings(_):
    # String-heavy: long quoted strings with escapes, plus long-bracket strings.
    return "".join(
        f'local s{i} = "the quick brown fox jumps over the lazy dog \\"{i}\\" \\n\\t"\n'
        f"local l{i} = [[long bracket string number {i} with some text inside]]\n"
        f"t[{i}] = 'single quoted {i}' .. s{i}\n"
        for i in range(100)
    )

def dense(_):
    # Worst case for per-token overhead: short tokens and no whitespace.
    return "".join(f"a{i}=b+c*(d-e)/f%g^h;t[{i}]={{x=1,y=2.5,z=0x{i:x}}};if a<=b then c=d..e end\n" for i in range(100))

CORPORA = {"code": code, "strings": strings, "dense": dense}

def main():
    out_dir, size_mb = sys.argv[1], int(sys.argv[2])
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.makedirs(out_dir, exist_ok=True)
    target = size_mb * 1_000_000
    for name, gen in CORPORA.items():
        path = os.path.join(out_dir, f"{name}_{size_mb}mb.lua")
        if os.path.exists(path):
            continue
        chunk = gen(root).encode()
        with open(path, "wb") as f:
            f.write(chunk * max(1, target // len(chunk)))
        print(f"generated {path}", file=sys.stderr)

if __name__ == "__main__":
    main()
