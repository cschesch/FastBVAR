# FastBVAR

FastBVAR is a performance-oriented derivative of Ferroni and Canova's
[BVAR toolbox](https://github.com/naffe15/BVAR_). Its governing rule is to
preserve the estimator, priors, missing-data treatment, posterior algorithm,
identification, API, outputs, option semantics, and random-number behavior.
An optimization is accepted only after comparison with a frozen upstream
reference.

FastBVAR is currently at the **Phase-1 baseline milestone**: the upstream
implementation is unchanged, the reference commit is pinned, deterministic
benchmarks and strict equivalence tests are present, and baseline profiling is
reproducible. No speedup is claimed yet.

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

See [COMPATIBILITY.md](COMPATIBILITY.md) for validated feature coverage and
[PERFORMANCE.md](PERFORMANCE.md) for profiling notes. Programmatic status is
returned by `fastbvar_capabilities`.

The frozen reference and exact commit are documented in
[UPSTREAM.md](UPSTREAM.md). This derivative remains licensed under GPL-3.0;
the original license and attribution are retained.
