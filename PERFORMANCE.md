# Performance notes

## Baseline

The frozen reference is upstream commit
`3975e6597cb23d82e4ebad162af29b2a1105b395`. Run:

```matlab
addpath('benchmarks', 'tests')
run_baseline_benchmarks
```

This writes a summary and per-function profiler tables to
`benchmarks/results/`. The original Phase-1 results were measured with GNU
Octave and are labelled accordingly. The later optimization results were
measured with MATLAB R2026a on Apple silicon.

### Phase-1 local baseline

These are GNU Octave 9.4.0 measurements, not MATLAB speed claims.

| Case | N | T | p | K | State | Wall time | Seconds/draw |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Small irregular | 5 | 180 | 6 | 2 | 30 | 0.482 s | 0.241 s |
| Small mixed frequency | 6 | 150 | 6 | 2 | 36 | 0.461 s | 0.231 s |
| Small high lag | 4 | 300 | 16 | 1 | 64 | 0.697 s | 0.697 s |

The profiler confirms that generic SVD work is material. Across these cases,
`svd` was called 904--1086 times and accounted for 0.066--0.270 seconds of
self time. `kfilternan` was called once per posterior draw and `kf_dk` once per
date per draw. In the high-lag case, the profiler attributed 0.270 seconds to
904 SVD calls, 0.082 seconds to `kfilternan`, 0.042 seconds to 300 `kf_dk`
calls, and 0.008 seconds to three `rfvar3` calls. These self times are not
additive inclusive timings, but they establish the first optimization target
without assuming it in advance.

Peak process memory is not exposed portably by Octave on this host and is
recorded as `NaN`; serialized output sizes are recorded in the CSV. MATLAB
profiling should add platform memory measurements where available.

### MATLAB R2026a baseline

| Case | N | T | p | K | State | Wall time | Seconds/draw |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Small irregular | 5 | 180 | 6 | 2 | 30 | 0.444 s | 0.222 s |
| Small mixed frequency | 6 | 150 | 6 | 2 | 36 | 0.242 s | 0.121 s |
| Small high lag | 4 | 300 | 16 | 1 | 64 | 0.271 s | 0.271 s |

MATLAB profiling confirms the missing-data state-space path as the first
target. `kfilternan` accounts for 0.126--0.162 seconds across these cases. In
the high-lag case it accounts for 0.162 of 0.200 seconds attributed to
`bvar_`, with 0.096 seconds in 300 `kf_dk` calls; three `rfvar3` calls account
for only 0.009 seconds. MATLAB does not report the built-in `svd` self-time as
a separate row here, but the call topology is visible in the Octave profile.

## Optimization 1: remove dead `Nmat` history

Upstream allocated `Nmat=zeros(ns,ns,T)`, never changed it, and used it only
inside a product that was identically zero. FastBVAR removes the allocation
and assigns the algebraically identical `Ct=Qt`. All small MATLAB equivalence
tests remain bitwise exact.

This removes exactly `8*ns^2*T` bytes from each active Kalman call: 9.8 MB for
the small high-lag case and approximately 1.65 GB for the target
`N=7, p=52, T=1560` case. Seven alternating MATLAB timing repetitions showed
0.97x in both small cases, which is within run-to-run noise; no runtime speedup
is claimed for this change. Results are in `dead_nmat_matlab.csv`.

## Optimization 2: skip unused simulation-smoother output

The `bvar_` missing-data path consumes filtered and smoothed conditional means
from `kfilternan`, but not its optional simulated-state output. FastBVAR skips
that output only for this internal call. Direct callers of `kfilternan` retain
the upstream default. To preserve later posterior draws bit-for-bit, the fast
path still generates and discards the same `N` normal variates at every date.

Five alternating MATLAB runs with longer chains produced:

| Case | K | Reference | FastBVAR | Speedup |
| --- | ---: | ---: | ---: | ---: |
| Small irregular | 10 | 0.511 s | 0.435 s | 1.17x |
| Small mixed frequency | 10 | 0.474 s | 0.408 s | 1.16x |
| Small high lag | 5 | 0.714 s | 0.679 s | 1.05x |

All public output fields, values, classes, dimensions, and RNG-dependent draws
remain bitwise identical in the small equivalence suite. Raw results are in
`skip_unused_simulation_matlab.csv`.

## Optimization 3: observation-dimensional Kalman factorization

For full-rank updates, `kf_dk` now factors the innovation covariance
`F=H*P*H'`, whose dimension is the number of observed variables, instead of
performing two SVD-based square-root operations involving the full `N*p`
state. Cholesky is used only when successful and well conditioned. Singular or
near-singular updates automatically execute the unchanged upstream SVD code;
a deliberately rank-deficient test verifies that fallback bit-for-bit.

Five alternating MATLAB runs produced cumulative speedups of 1.77x for small
irregular missing data, 1.84x for small mixed frequency, and 2.72x for the
small high-lag case. The operation reordering is validated under the current
`1e-6` absolute and relative contract over the recursive result structure. The worst observed
absolute discrepancy was `8.95e-9` in a mixed-frequency posterior coefficient
mean (allowed by the relative term); filtered observations differed by at most
`6.33e-15`. Raw timings are in `innovation_cholesky_matlab.csv`.

## Optimization 4: structured companion propagation

For pure stock-variable VAR states with `ns >= 128`, covariance propagation
uses the exact block identity for `G=[A; I 0]` instead of generic dense
`G*P*G'`. A microbenchmark established the crossover: the block path is 2.25x
faster at `ns=140` and 3.33x at `ns=364`, but slower at `ns=56`; smaller or
augmented mixed-frequency states retain dense BLAS. Results are in
`companion_propagation_matlab.csv`.

## Optimization 5: toolbox-free Lyapunov doubling

Stationary initialization now uses squared Smith iteration, checking both
convergence and the Lyapunov residual before accepting the result. Failure
falls back to the unchanged Schur solver. Automated tests cover the fast solve
at `1e-10` and a bitwise nonconvergent fallback.

## Optimization 6: matrix-free smoother and shared prediction

The forward filter now computes each predicted state once and shares it with
the forecast and update code. Companion-state lag rows are copied rather than
densely multiplied. In the backward pass, FastBVAR applies
`L'*r = A'*r - Z*K'*A'*r` directly instead of constructing the full dense
`L=A-A*K*Z'` at every date. Simulation-only smoother history is no longer
stored when `bvar_` has disabled that output.

With these changes, the p=52 five-run FastBVAR median is 1.325 seconds per
draw versus 38.519 seconds for the frozen reference, a 29.08x speedup.
Individual runs are recorded in `p52_repeated_matlab.csv`.

A separate end-to-end `N=7, T=1560, p=52, K=1` comparison against the frozen
reference passed the `1e-6` contract with a worst absolute difference of only
`9.27e-15` (in `yfill`). That validation run is recorded in
`p52_equivalence_matlab.csv`.

## RNG compatibility

The default `options.preserve_rng=true` retains upstream stream positioning.
Set it to `false` to omit random draws that fed an unused simulation-smoother
output. This intentionally changes later same-seed posterior draws without
changing their target distribution; its runtime effect is small relative to
the matrix optimizations.

## Large synthetic benchmarks

Observed MATLAB R2026a timings at `K=1`:

| Case | Reference | FastBVAR | Speedup |
| --- | ---: | ---: | ---: |
| Gold p=13 | 1.572 s | 0.586 s | 2.68x |
| Gold p=52 | 33.758 s | 5.637 s | 5.99x |
| Fiscal-monetary | 0.761 s | 0.162 s | 4.68x |

These are initial cold one-draw runs retained for reproducibility; the later
p=52 repeated-median result is reported above. Runtime
still scales approximately with `K` on the missing-data Gibbs path; realistic
multi-draw scaling and remaining full covariance-history storage require the
next profiling pass. Reproduce with `run_large_benchmarks(1)`; raw results are
in `large_matlab.csv`.
