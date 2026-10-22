#!/usr/bin/env bash
# Golden-output test runner for detlua.
#
# Every tests/**/NAME.lua is run with `$DETLUA NAME.lua`; its stdout must match
# NAME.expected exactly and it must exit 0 within $TIMEOUT seconds.
# If the test's directory has a .args file, its contents are passed after the
# filename (e.g. tests/lexer/.args holds "-lex").
#
# usage: tests/run.sh [-v] [--regen] DIR... [-- FILTER]
#   -v       show full diffs (default: first 20 lines)
#   --regen  rewrite .expected files using a reference lua ($LUA, default `lua`)
#   FILTER   only run tests whose path contains this substring
set -u

DETLUA=${DETLUA:-./detlua}
LUA=${LUA:-lua}
TIMEOUT=${TIMEOUT:-10}

verbose=0
regen=0
filter=""
dirs=()
while [ $# -gt 0 ]; do
	case "$1" in
		-v) verbose=1 ;;
		--regen) regen=1 ;;
		--) shift; filter="${1:-}"; break ;;
		*) dirs+=("$1") ;;
	esac
	shift
done
[ ${#dirs[@]} -eq 0 ] && dirs=(tests)

if [ -t 1 ]; then
	RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' DIM=$'\033[2m' RESET=$'\033[0m'
else
	RED="" GREEN="" YELLOW="" DIM="" RESET=""
fi

# macOS has no coreutils `timeout`; perl's alarm is portable.
run_limited() { perl -e 'alarm shift; exec @ARGV or die "exec: $!\n"' "$TIMEOUT" "$@"; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass=0 fail=0 missing=0
failed=()

while IFS= read -r t; do
	[ -n "$filter" ] && [[ "$t" != *"$filter"* ]] && continue
	exp="${t%.lua}.expected"
	args=()
	argsfile="$(dirname "$t")/.args"
	[ -f "$argsfile" ] && read -r -a args < "$argsfile"

	if [ $regen -eq 1 ]; then
		# Reference lua can only produce program output, not detlua-specific modes.
		if [ ${#args[@]} -gt 0 ]; then
			echo "${DIM}skip${RESET}  $t (uses $argsfile)"
			continue
		fi
		if ! "$LUA" "$t" > "$exp" 2> "$tmp/err"; then
			echo "${RED}regen error${RESET} $t"; cat "$tmp/err"
		else
			echo "${DIM}wrote${RESET} $exp"
		fi
		continue
	fi

	if [ ! -f "$exp" ]; then
		echo "${YELLOW}NOEXP${RESET} $t"
		missing=$((missing + 1))
		continue
	fi

	start=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000')
	run_limited "$DETLUA" "$t" ${args[@]+"${args[@]}"} > "$tmp/out" 2> "$tmp/err"
	code=$?
	end=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000')
	ms=$((end - start))

	reason=""
	if [ $code -eq 142 ]; then
		reason="timed out after ${TIMEOUT}s"
	elif [ $code -ne 0 ]; then
		reason="exit code $code"
	elif ! cmp -s "$exp" "$tmp/out"; then
		reason="output mismatch"
	fi

	if [ -z "$reason" ]; then
		echo "${GREEN}PASS${RESET}  $t ${DIM}(${ms}ms)${RESET}"
		pass=$((pass + 1))
	else
		echo "${RED}FAIL${RESET}  $t ${DIM}(${ms}ms)${RESET} - $reason"
		fail=$((fail + 1))
		failed+=("$t")
		lines=20; [ $verbose -eq 1 ] && lines=100000
		diff -u --label expected --label actual "$exp" "$tmp/out" | tail -n +3 | head -n $lines | sed 's/^/      /'
		if [ -s "$tmp/err" ]; then
			echo "      ${DIM}stderr:${RESET}"
			head -n $lines "$tmp/err" | sed 's/^/      /'
		fi
	fi
done < <(find "${dirs[@]}" -name '*.lua' | sort)

[ $regen -eq 1 ] && exit 0

echo
summary="$pass passed, $fail failed"
[ $missing -gt 0 ] && summary="$summary, $missing missing .expected"
if [ $fail -eq 0 ]; then
	echo "${GREEN}${summary}${RESET}"
else
	echo "${RED}${summary}${RESET}"
	exit 1
fi
