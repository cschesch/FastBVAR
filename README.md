# FastBVAR

FastBVAR is a performance-oriented derivative of Ferroni and Canova's
[BVAR toolbox](https://github.com/naffe15/BVAR_). Its governing rule is to
preserve the estimator, priors, missing-data treatment, posterior algorithm,
identification, API, outputs, option semantics, and random-number behavior.
An optimization is accepted only after comparison with a frozen upstream
reference.

FastBVAR is currently at the **Phase-1 baseline milestone**: the upstream
reference is pinned, deterministic benchmarks and strict equivalence tests are
present, and the missing-data Kalman path has validated fast paths with robust
legacy fallbacks. On the checked-in MATLAB R2026a synthetic `K=1` benchmarks,
speedups range from 2.68x to 5.99x; see `PERFORMANCE.md` for scope and caveats.

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

The equivalence suite uses the documented `1e-9` absolute/relative tolerance
for the operation-reordered Kalman fast path and bitwise comparison for its
legacy singular-update fallback.

See [COMPATIBILITY.md](COMPATIBILITY.md) for validated feature coverage and
[PERFORMANCE.md](PERFORMANCE.md) for profiling notes. Programmatic status is
returned by `fastbvar_capabilities`.

The frozen reference and exact commit are documented in
[UPSTREAM.md](UPSTREAM.md). This derivative remains licensed under GPL-3.0;
the original license and attribution are retained.
