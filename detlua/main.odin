package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

Flags :: struct {
	filepath:     string,
	is_lex:       bool,
	is_bench_lex: bool,
}

parse_flags :: proc(allocator: mem.Allocator = context.allocator) -> (flags: Flags, err: string) {
	for arg in os.args[1:] {
		if strings.has_prefix(arg, "-") {
			if arg == "-lex" {
				flags.is_lex = true
			} else if arg == "-bench-lex" {
				flags.is_bench_lex = true
			} else {
				err = fmt.aprintf("unrecognized flag: %s", arg, allocator)
				break
			}
		} else {
			if flags.filepath != "" {
				err = strings.clone("multiple files specified when only one is allowed", allocator)
				break
			} else {
				flags.filepath = arg
			}
		}
	}
	return
}

main :: proc() {
	flags, flag_err := parse_flags()
	if flag_err != "" {
		fmt.eprintf("bad flags: %v\n", flag_err)
		delete(flag_err, context.allocator)
		os.exit(1)
	}
	if flags.filepath == "" {
		fmt.eprintf("usage: detlua file.lua [-lex | -bench-lex]\n")
		os.exit(1)
	}
	if flags.is_bench_lex {
		bench_lexer(flags.filepath)
		return
	}
	file_bytes, open_err := os.read_entire_file(flags.filepath, context.allocator)
	if open_err != nil {
		fmt.eprintf("%s: %v\n", flags.filepath, open_err)
		os.exit(1)
	}
	defer delete(file_bytes, context.allocator)

	tkf := lex_file(file_bytes)
	defer token_file_destroy(&tkf)

	if flags.is_lex {
		for tk in tkf.toks {
			#partial switch tk.ty {
			case .Whitespace, .NL, .Comment, .EOF:
				fmt.printf("%d %s\n", tk.loc, token_names[tk.ty])
			case:
				fmt.printf("%d %s %s\n", tk.loc, token_names[tk.ty], token_v(tkf.src, tk))
			}
		}
	}
}
