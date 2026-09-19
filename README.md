# FastBVAR

FastBVAR is a performance-focused implementation of the Ferroni–Canova
Bayesian VAR. The pinned upstream checkout is retained as a frozen reference;
the rest of the repository contains only the BVAR runtime, its required
dependencies, the optimized code, and reproducibility scripts.

```bash
git clone --recurse-submodules https://github.com/cschesch/FastBVAR.git
```

```matlab
addpath('FastBVAR','FastBVAR/bvartools')
options = struct('K',1000,'noprint',true);
BVAR = fastbvar_(y,lags,options);
```

All upstream BVAR options are accepted. `verify_option_coverage` compares a
small baseline with every option varied once; options with dependencies are
tested as the smallest valid bundle. Those exact passing signatures are stored
in `fastbvar_validation_registry`. A combination not in the registry still
runs, but emits `FastBVAR:UnvalidatedCombination` with instructions to check it:

```matlab
validate_option_combination(y_small,lags,options)
```

This comparison runs frozen BVAR and FastBVAR with identical RNG state and
marks a passing signature as validated for the MATLAB session. An arbitrary
`objective_function` callback always remains unvalidated because built-in
fixtures cannot certify user code. Unknown option names are errors.

Fast mode omits random draws used only by an upstream simulation result that
`bvar_` discards. Set `options.verify_mode=true` to reproduce upstream RNG
positioning. The option sweep uses a process pool when Parallel Computing
Toolbox is available, while optimizer fixtures remain serial because upstream
optimizers write shared scratch files.

```matlab
verify_exactness          % core modes and p=52 frozen-reference checks
verify_option_coverage    % every one-at-a-time option fixture
compare_timing            % p=13 and p=52 timings
```

On MATLAB R2026a on an Apple-silicon laptop, the synthetic `N=7, T=1560,
p=52` workload is roughly 45–50× faster than the frozen reference and matches
its returned BVAR values within the project tolerance of `1e-6` (observed worst
difference below `1.1e-8`). Results vary by machine.

The reference is upstream commit
`3975e6597cb23d82e4ebad162af29b2a1105b395`. GPL-3.0 licensing and attribution
are retained.
