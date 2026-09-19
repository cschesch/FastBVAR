# FastBVAR

FastBVAR is a performance-oriented derivative of Ferroni and Canova's
[BVAR toolbox](https://github.com/naffe15/BVAR_). Its governing rule is to
preserve the estimator, priors, missing-data treatment, posterior algorithm,
identification, API, outputs, option semantics, and random-number behavior.
An optimization is accepted only after comparison with a frozen upstream
reference.

FastBVAR has a pinned upstream reference, deterministic benchmarks, strict
equivalence tests, and validated missing-data Kalman fast paths with robust
legacy fallbacks. On the checked-in MATLAB R2026a synthetic `K=1` benchmarks,
speedups reach 29.1x on the repeated Gold p=52 benchmark; see
`PERFORMANCE.md` for scope and caveats.

## Install

```bash
git clone --recurse-submodules https://github.com/cschesch/FastBVAR.git
```

In MATLAB, add the package folders:

```matlab
addpath('FastBVAR')
addpath('FastBVAR/bvartools')
addpath('FastBVAR/cmintools')
```

Existing scripts can continue to call:

```matlab
BVAR = bvar_(y, lags, options);
```

The explicit alias is:

```matlab
BVAR = fastbvar_(y, lags, options);
```

## Verify and benchmark

```matlab
addpath('tests', 'benchmarks')
run_equivalence_tests
run_baseline_benchmarks
```

The equivalence suite uses the documented `1e-6` absolute/relative tolerance
for the operation-reordered Kalman fast path and bitwise comparison for its
legacy singular-update fallback.

Exact upstream RNG positioning remains the default. Users who do not need
same-seed draw identity can set `options.preserve_rng = false` to skip draws
associated only with an unused simulation-smoother output.

See [COMPATIBILITY.md](COMPATIBILITY.md) for validated feature coverage and
[PERFORMANCE.md](PERFORMANCE.md) for profiling notes. Programmatic status is
returned by `fastbvar_capabilities`.

The frozen reference and exact commit are documented in
[UPSTREAM.md](UPSTREAM.md). This derivative remains licensed under GPL-3.0;
the original license and attribution are retained.
