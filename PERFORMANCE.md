# Performance notes

## Baseline

The frozen reference is upstream commit
`3975e6597cb23d82e4ebad162af29b2a1105b395`. Run:

```matlab
addpath('benchmarks', 'tests')
run_baseline_benchmarks
```

This writes a summary and per-function profiler tables to
`benchmarks/results/`. Results committed during Phase 1 were measured with
GNU Octave and are labelled accordingly; MATLAB results must be generated on
a MATLAB host before making MATLAB speed claims.

No numerical optimization has been made yet. Candidate bottlenecks will be
ranked from the baseline profiles before production code changes.

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
