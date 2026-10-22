package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:time"

BENCH_DEFAULT_ITERS :: 10

// Bench_Stats summarises throughput samples in GB/s.
Bench_Stats :: struct {
	min, p50, p90, max, mean, sd: f64,
}

bench_stats :: proc(samples: []f64) -> (s: Bench_Stats) {
	slice.sort(samples)
	n := len(samples)
	s.min = samples[0]
	s.max = samples[n - 1]
	s.p50 = bench_percentile(samples, 0.50)
	s.p90 = bench_percentile(samples, 0.90)
	for x in samples {
		s.mean += x
	}
	s.mean /= f64(n)
	for x in samples {
		s.sd += (x - s.mean) * (x - s.mean)
	}
	s.sd = math.sqrt(s.sd / f64(max(n - 1, 1)))
	return
}

// bench_percentile linearly interpolates the q-th quantile of sorted samples.
bench_percentile :: proc(sorted: []f64, q: f64) -> f64 {
	pos := q * f64(len(sorted) - 1)
	lo := int(pos)
	hi := min(lo + 1, len(sorted) - 1)
	return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - f64(lo))
}

bench_row :: proc(name: string, s: Bench_Stats) {
	col :: proc(x: f64) -> string {return fmt.tprintf("%.3f", x)}
	fmt.printf(
		"  %-5s %8s %8s %8s %8s %8s %8s  %8s\n",
		name,
		col(s.min),
		col(s.p50),
		col(s.mean),
		col(s.p90),
		col(s.max),
		fmt.tprintf("%.1f%%", 100 * s.sd / s.mean),
		col(s.p50 * 8),
	)
}

// bench_lexer reports the distribution of lex_file throughput on the file at
// path, baselined against reading the same file into memory. Each phase does
// one untimed warmup run, then BENCH_ITERS (env, default 10) timed runs.
bench_lexer :: proc(path: string) {
	iters := BENCH_DEFAULT_ITERS
	if v, ok := strconv.parse_int(os.get_env("BENCH_ITERS", context.temp_allocator)); ok && v > 0 {
		iters = v
	}
	read_gbs := make([]f64, iters)
	lex_gbs := make([]f64, iters)
	lex_ns_per_tok := make([]f64, iters)
	defer delete(read_gbs)
	defer delete(lex_gbs)
	defer delete(lex_ns_per_tok)

	src: []byte
	for i in -1 ..< iters {
		delete(src)
		start := time.tick_now()
		data, err := os.read_entire_file(path, context.allocator)
		elapsed := time.tick_since(start)
		if err != nil {
			fmt.eprintf("%s: %v\n", path, err)
			os.exit(1)
		}
		src = data
		if i >= 0 {
			read_gbs[i] = f64(len(src)) / time.duration_seconds(elapsed) / 1e9
		}
	}
	defer delete(src)

	ntokens := 0
	for i in -1 ..< iters {
		start := time.tick_now()
		tkf := lex_file(src)
		elapsed := time.tick_since(start)
		ntokens = len(tkf.toks)
		token_file_destroy(&tkf)
		if i >= 0 {
			secs := time.duration_seconds(elapsed)
			lex_gbs[i] = f64(len(src)) / secs / 1e9
			lex_ns_per_tok[i] = secs * 1e9 / f64(max(ntokens, 1))
		}
	}

	read := bench_stats(read_gbs)
	lex := bench_stats(lex_gbs)
	ns := bench_stats(lex_ns_per_tok)
	fmt.printf(
		"%s  %.1f MB, %d tokens, %d runs (+1 warmup)\n",
		path,
		f64(len(src)) / 1e6,
		ntokens,
		iters,
	)
	fmt.printf("  %-5s %8s %8s %8s %8s %8s %8s  %8s\n", "GB/s", "min", "p50", "mean", "p90", "max", "cv", "Gbit/s")
	bench_row("read", read)
	bench_row("lex", lex)
	fmt.printf("  lex p50 = %.3fx read p50, %.2f ns/token (p50)\n", lex.p50 / read.p50, ns.p50)
}
