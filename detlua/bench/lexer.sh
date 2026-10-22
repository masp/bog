#!/usr/bin/env bash
# Lexer throughput benchmark: `$DETLUA FILE -bench-lex` on each generated corpus.
set -eu

DETLUA=${DETLUA:-./detlua-release}
SIZE_MB=${SIZE_MB:-64}
DATA=${DATA:-bench/data}

python3 bench/gen_lexer_data.py "$DATA" "$SIZE_MB"
for f in "$DATA"/*_"${SIZE_MB}"mb.lua; do
	"$DETLUA" "$f" -bench-lex
	echo
done
