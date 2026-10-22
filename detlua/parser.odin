package main

import "core:mem"

Parser :: struct {
	src:  []Token_Tup,
	curr: int, // ptr to current token
}

Parse_Tree :: struct {
	stmts: []^Node,
}

Node_Ident :: struct {
	name: Token_Tup,
}

Node_String :: struct {
	value: Token_Tup,
}

Node_Func_Apply :: struct {
	callee: ^Node,
	args:   []^Node,
}

Node :: union {
	Node_Ident,
	Node_String,
	Node_Func_Apply,
}

parse_file :: proc(
	src: []byte,
	allocator: mem.Allocator = context.allocator,
) -> (
	Token_File,
	^Parse_Tree,
) {
	tkf := lex_file(src, allocator)
	return tkf, new(Parse_Tree)
}

parse_expr :: proc(p: ^Parser, tkf: ^Token_File) -> ^Node {
	if p.curr >= len(tkf.toks) {
		return nil
	}

	tok := tkf.toks[p.curr]
	switch tok.ty {
	case Token.String:
	case Token.Number:
		return parse_binary()
	}
}

// 2 * 3 + 5
// (2*3) + 5
// 2 + 3 * 5
// 2 + (3*5)
// 2 * 3 * 5

parse_add :: proc(p: ^Parser, tkf: ^Token_File) -> ^Node {
	left := parse_mul(p, tkf)
	next := peek(p, tkf)
	if next.ty == Token.Star || next.ty == Token.Slash {

	}
}

parse_mul :: proc(p: ^Parser, tkf: ^Token_File) -> ^Node {

}

peek :: proc(p: ^Parser, tkf: ^Token_File) -> Token_Tup {
	if p.curr + 1 >= len(tkf.toks) {
		return Token_Tup{ty = Token.EOF}
	}
	return tkf.toks[p.curr + 1]
}
