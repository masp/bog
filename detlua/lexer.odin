package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

Lexer :: struct {
	p: int,
}

Token :: enum u8 {
	// Literals
	String,
	Number,
	// Ident
	Ident,
	// Symbols
	Lparen,
	Rparen,
	Lbrace,
	Rbrace,
	Lbracket,
	Rbracket,
	Plus,
	Minus,
	Star,
	Slash,
	Percent,
	Caret,
	Hash,
	Eq,
	Ne,
	Le,
	Ge,
	Lt,
	Gt,
	Assign,
	Semi,
	Colon,
	Comma,
	Dot,
	Concat,
	Dots,
	// Keywords
	And,
	Break,
	Do,
	Else,
	Elseif,
	End,
	False,
	For,
	Function,
	If,
	In,
	Local,
	Nil,
	Not,
	Or,
	Repeat,
	Return,
	Then,
	True,
	Until,
	While,
	EOF,
	Whitespace,
	NL,
	Comment,

	// Errors
	Error_UnterminatedString = 200,
	Error_BadSeq = 201,
	Error_BadByte = 202,
	Error_UnterminatedComment = 203,
	Error_BadNumber = 204,
}

// token_names maps each Token to the name written to stdout by -lex.
token_names := #sparse[Token]string {
	.String                    = "String",
	.Number                    = "Number",
	.Ident                     = "Ident",
	.Lparen                    = "Lparen",
	.Rparen                    = "Rparen",
	.Lbrace                    = "Lbrace",
	.Rbrace                    = "Rbrace",
	.Lbracket                  = "Lbracket",
	.Rbracket                  = "Rbracket",
	.Plus                      = "Plus",
	.Minus                     = "Minus",
	.Star                      = "Star",
	.Slash                     = "Slash",
	.Percent                   = "Percent",
	.Caret                     = "Caret",
	.Hash                      = "Hash",
	.Eq                        = "Eq",
	.Ne                        = "Ne",
	.Le                        = "Le",
	.Ge                        = "Ge",
	.Lt                        = "Lt",
	.Gt                        = "Gt",
	.Assign                    = "Assign",
	.Semi                      = "Semi",
	.Colon                     = "Colon",
	.Comma                     = "Comma",
	.Dot                       = "Dot",
	.Concat                    = "Concat",
	.Dots                      = "Dots",
	.And                       = "And",
	.Break                     = "Break",
	.Do                        = "Do",
	.Else                      = "Else",
	.Elseif                    = "Elseif",
	.End                       = "End",
	.False                     = "False",
	.For                       = "For",
	.Function                  = "Function",
	.If                        = "If",
	.In                        = "In",
	.Local                     = "Local",
	.Nil                       = "Nil",
	.Not                       = "Not",
	.Or                        = "Or",
	.Repeat                    = "Repeat",
	.Return                    = "Return",
	.Then                      = "Then",
	.True                      = "True",
	.Until                     = "Until",
	.While                     = "While",
	.EOF                       = "EOF",
	.Whitespace                = "Whitespace",
	.NL                        = "NL",
	.Comment                   = "Comment",
	.Error_UnterminatedString  = "Error_UnterminatedString",
	.Error_BadSeq              = "Error_BadSeq",
	.Error_BadByte             = "Error_BadByte",
	.Error_UnterminatedComment = "Error_UnterminatedComment",
	.Error_BadNumber           = "Error_BadNumber",
}

token_iserror :: proc(t: Token) -> bool {
	return t >= Token.Error_UnterminatedString
}

token_errstring :: proc(t: Token) -> string {
	if t == Token.Error_UnterminatedString {
		return "string is missing a closing quote"
	}
	if t == Token.Error_BadSeq {
		return "sequence of bytes is invalid"
	}
	if t == Token.Error_BadByte {
		return "byte is not valid"
	}
	if t == Token.Error_UnterminatedComment {
		return "block comment is missing its closing bracket"
	}
	if t == Token.Error_BadNumber {
		return "number is malformed"
	}
	return "not an error"
}

Loc :: int
Span :: struct {
	beg, end: Loc,
}

// Token_Tup is stored #soa, so each token costs 1 + 8 + 8 = 17 bytes.
Token_Tup :: struct {
	ty:   Token,
	loc:  Loc,
	vlen: int, // the token's bytes are src[loc:][:vlen]; see token_v
}

token_v :: proc(src: []byte, tk: Token_Tup) -> []byte {
	return src[tk.loc:][:tk.vlen]
}

Token_File :: struct {
	src:       []byte,
	toks:      #soa[dynamic]Token_Tup,
	allocator: mem.Allocator,
}

token_file_destroy :: proc(tk: ^Token_File) {
	delete(tk.src, allocator = tk.allocator)
	delete(tk.toks)
}

// lex_all produces all the tokens and positions found in src.
//
// Memory: Use token_file_destroy to release.
lex_file :: proc(src: []byte, allocator: mem.Allocator = context.allocator) -> Token_File {
	l: Lexer
	tk: Token_File
	tk.src = make([]byte, len(src))
	tk.toks = make(#soa[dynamic]Token_Tup)
	copy(tk.src, src)
	for {
		ty, v := lex_next(&l, src)
		append(&tk.toks, Token_Tup{ty = ty, loc = l.p, vlen = len(v)})
		if ty == Token.EOF || token_iserror(ty) {
			break
		}
		l.p = l.p + len(v)
	}
	return tk
}


// lex_next consumes the next token returning the type and the full bytes containing the token.
// Always l.p + len(tok) = l.p after calling lex_next if tok != nil.
lex_next :: proc(l: ^Lexer, src: []byte) -> (ty: Token, tok: []byte) {
	if l.p >= len(src) {
		return Token.EOF, nil
	}
	c := src[l.p]
	next := peek(src, l.p + 1)

	// Ident and keywords
	if is_alpha(c) || c == '_' {
		return lex_next_ident(l, src)
	}

	// Numbers, including ones starting with '.' like .5
	if is_digit(c) || (c == '.' && is_digit(next)) {
		return lex_next_number(l, src)
	}

	// Strings
	if c == '"' || c == '\'' {
		return lex_next_string(l, src, c)
	}
	if c == '[' && long_bracket_level(src, l.p) >= 0 {
		return lex_next_long_string(l, src)
	}

	// Comments
	if c == '-' && next == '-' {
		return lex_next_comment(l, src)
	}

	// Whitespace
	if c == ' ' || c == '\t' {
		return lex_whitespace(l, src)
	}
	if c == '\n' || c == '\r' {
		return lex_nl(l, src)
	}

	// Symbols, longest match first
	switch c {
	case '.':
		if next == '.' {
			if peek(src, l.p + 2) == '.' {
				return Token.Dots, src[l.p:l.p + 3]
			}
			return Token.Concat, src[l.p:l.p + 2]
		}
		return Token.Dot, src[l.p:l.p + 1]
	case '=':
		if next == '=' {
			return Token.Eq, src[l.p:l.p + 2]
		}
		return Token.Assign, src[l.p:l.p + 1]
	case '<':
		if next == '=' {
			return Token.Le, src[l.p:l.p + 2]
		}
		return Token.Lt, src[l.p:l.p + 1]
	case '>':
		if next == '=' {
			return Token.Ge, src[l.p:l.p + 2]
		}
		return Token.Gt, src[l.p:l.p + 1]
	case '~':
		if next == '=' {
			return Token.Ne, src[l.p:l.p + 2]
		}
		return Token.Error_BadSeq, src[l.p:l.p + 1]
	case '[':
		if next == '=' {
			// [= that never reaches a second [ is an invalid long bracket
			return Token.Error_BadSeq, src[l.p:l.p + 2]
		}
		return Token.Lbracket, src[l.p:l.p + 1]
	case '(':
		return Token.Lparen, src[l.p:l.p + 1]
	case ')':
		return Token.Rparen, src[l.p:l.p + 1]
	case '{':
		return Token.Lbrace, src[l.p:l.p + 1]
	case '}':
		return Token.Rbrace, src[l.p:l.p + 1]
	case ']':
		return Token.Rbracket, src[l.p:l.p + 1]
	case '+':
		return Token.Plus, src[l.p:l.p + 1]
	case '-':
		return Token.Minus, src[l.p:l.p + 1]
	case '*':
		return Token.Star, src[l.p:l.p + 1]
	case '/':
		return Token.Slash, src[l.p:l.p + 1]
	case '%':
		return Token.Percent, src[l.p:l.p + 1]
	case '^':
		return Token.Caret, src[l.p:l.p + 1]
	case '#':
		return Token.Hash, src[l.p:l.p + 1]
	case ';':
		return Token.Semi, src[l.p:l.p + 1]
	case ':':
		return Token.Colon, src[l.p:l.p + 1]
	case ',':
		return Token.Comma, src[l.p:l.p + 1]
	}

	return Token.Error_BadByte, src[l.p:l.p + 1]
}

// peek returns src[i], or 0 past the end of src.
peek :: proc(src: []byte, i: int) -> byte {
	return src[i] if i < len(src) else 0
}

is_alpha :: proc(c: byte) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

is_digit :: proc(c: byte) -> bool {
	return c >= '0' && c <= '9'
}

is_hex :: proc(c: byte) -> bool {
	return is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

lex_next_ident :: proc(l: ^Lexer, src: []byte) -> (Token, []byte) {
	beg := l.p
	end := l.p
	for end < len(src) && (is_alpha(src[end]) || is_digit(src[end]) || src[end] == '_') {
		end += 1
	}
	return keyword_or_ident(src[beg:end]), src[beg:end]
}

keyword_or_ident :: proc(word: []byte) -> Token {
	switch string(word) {
	case "and":
		return Token.And
	case "break":
		return Token.Break
	case "do":
		return Token.Do
	case "else":
		return Token.Else
	case "elseif":
		return Token.Elseif
	case "end":
		return Token.End
	case "false":
		return Token.False
	case "for":
		return Token.For
	case "function":
		return Token.Function
	case "if":
		return Token.If
	case "in":
		return Token.In
	case "local":
		return Token.Local
	case "nil":
		return Token.Nil
	case "not":
		return Token.Not
	case "or":
		return Token.Or
	case "repeat":
		return Token.Repeat
	case "return":
		return Token.Return
	case "then":
		return Token.Then
	case "true":
		return Token.True
	case "until":
		return Token.Until
	case "while":
		return Token.While
	}
	return Token.Ident
}

// lex_next_number handles decimal (3, 3.0, .5, 314.16e-2) and hex (0xff) numbers.
lex_next_number :: proc(l: ^Lexer, src: []byte) -> (Token, []byte) {
	beg := l.p
	end := l.p
	if src[end] == '0' && (peek(src, end + 1) == 'x' || peek(src, end + 1) == 'X') {
		end += 2
		digits := end
		for end < len(src) && is_hex(src[end]) {
			end += 1
		}
		if end == digits {
			return Token.Error_BadNumber, src[beg:end]
		}
	} else {
		for end < len(src) && is_digit(src[end]) {
			end += 1
		}
		if peek(src, end) == '.' {
			end += 1
			for end < len(src) && is_digit(src[end]) {
				end += 1
			}
		}
		if peek(src, end) == 'e' || peek(src, end) == 'E' {
			end += 1
			if peek(src, end) == '+' || peek(src, end) == '-' {
				end += 1
			}
			digits := end
			for end < len(src) && is_digit(src[end]) {
				end += 1
			}
			if end == digits {
				return Token.Error_BadNumber, src[beg:end]
			}
		}
	}
	// A number running straight into a letter, _ or . (3x, 1.2.3, 3..2) is malformed.
	c := peek(src, end)
	if is_alpha(c) || c == '_' || c == '.' {
		return Token.Error_BadNumber, src[beg:end + 1]
	}
	return Token.Number, src[beg:end]
}

lex_next_string :: proc(l: ^Lexer, src: []byte, q: byte) -> (Token, []byte) {
	beg := l.p
	// skip first byte to prevent early term
	for end := l.p + 1; end < len(src); end += 1 {
		switch src[end] {
		case q:
			return Token.String, src[beg:end + 1]
		case '\\':
			end += 1 // skip the escaped byte, so \" and \\ don't end the string
		case '\n', '\r':
			return Token.Error_UnterminatedString, src[beg:end]
		}
	}
	return Token.Error_UnterminatedString, src[beg:] // unterminated string
}

// long_bracket_level returns n for an opening long bracket [ followed by n '='
// and another [ at src[p], or -1 if there isn't one.
long_bracket_level :: proc(src: []byte, p: int) -> int {
	if peek(src, p) != '[' {
		return -1
	}
	n := 0
	for peek(src, p + 1 + n) == '=' {
		n += 1
	}
	return n if peek(src, p + 1 + n) == '[' else -1
}

// long_bracket_close returns the index just past the closing ]=*] of the given
// level, searching from p, or -1 if it is never closed.
long_bracket_close :: proc(src: []byte, p: int, level: int) -> int {
	outer: for i := p; i < len(src); i += 1 {
		if src[i] != ']' {
			continue
		}
		for j in 1 ..= level {
			if peek(src, i + j) != '=' {
				continue outer
			}
		}
		if peek(src, i + level + 1) == ']' {
			return i + level + 2
		}
	}
	return -1
}

lex_next_long_string :: proc(l: ^Lexer, src: []byte) -> (Token, []byte) {
	level := long_bracket_level(src, l.p)
	end := long_bracket_close(src, l.p + level + 2, level)
	if end < 0 {
		return Token.Error_UnterminatedString, src[l.p:]
	}
	return Token.String, src[l.p:end]
}

// lex_next_comment handles -- line comments and --[[ ]] / --[==[ ]==] block comments.
// A line comment stops before the newline (and any \r ahead of it).
lex_next_comment :: proc(l: ^Lexer, src: []byte) -> (Token, []byte) {
	beg := l.p
	if level := long_bracket_level(src, beg + 2); level >= 0 {
		end := long_bracket_close(src, beg + 2 + level + 2, level)
		if end < 0 {
			return Token.Error_UnterminatedComment, src[beg:]
		}
		return Token.Comment, src[beg:end]
	}
	end := beg + 2
	for end < len(src) && src[end] != '\n' {
		end += 1
	}
	for end > beg + 2 && src[end - 1] == '\r' {
		end -= 1
	}
	return Token.Comment, src[beg:end]
}

lex_nl :: proc(l: ^Lexer, src: []byte) -> (Token, []byte) {
	beg := l.p
	end := l.p
	// Eat all \r before a \n as a single NL token.
	for end < len(src) && src[end] == '\r' {
		end += 1
	}
	if end >= len(src) || src[end] != '\n' {
		// Just a bunch of '\r', return that as an error
		return Token.Error_BadSeq, src[beg:end]
	}
	return Token.NL, src[beg:end + 1] // +1 to include the \n
}

lex_whitespace :: proc(l: ^Lexer, src: []byte) -> (Token, []byte) {
	beg := l.p
	end := l.p
	for end < len(src) && (src[end] == ' ' || src[end] == '\t') {
		end += 1
	}
	return Token.Whitespace, src[beg:end]
}
