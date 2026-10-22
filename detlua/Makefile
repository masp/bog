ODIN      ?= odin
ODINFLAGS ?=
BIN       := detlua
SRCS      := $(shell find . -name '*.odin' -not -path './tests/*')

# Run a subset by path substring: make fulltest T=closure
T ?=
LUA ?= lua
SIZE_MB ?= 64

.PHONY: all build test lexer fulltest regen bench-lexer clean

all: $(BIN)
build: $(BIN)

$(BIN): $(SRCS)
	$(ODIN) build . -out:$(BIN) $(ODINFLAGS)

# Optimised build used for benchmarks.
$(BIN)-release: $(SRCS)
	$(ODIN) build . -out:$@ -o:speed $(ODINFLAGS)

# Small, fast smoke suite: run on every change.
test: $(BIN)
	@./tests/run.sh tests/smoke -- "$(T)"

# Lexer only: `detlua FILE.lua -lex` must print one raw token per line.
lexer: $(BIN)
	@./tests/run.sh tests/lexer -- "$(T)"

# Everything under tests/.
fulltest: $(BIN)
	@./tests/run.sh tests -- "$(T)"

# Regenerate .expected files with a reference Lua 5.1: make regen LUA=/path/to/lua
regen:
	@LUA="$(LUA)" ./tests/run.sh --regen tests -- "$(T)"

# Lexer throughput vs. file-read baseline on generated corpora (bench/data/).
# make bench-lexer SIZE_MB=256
bench-lexer: $(BIN)-release
	@SIZE_MB=$(SIZE_MB) ./bench/lexer.sh

clean:
	rm -f $(BIN) $(BIN)-release
