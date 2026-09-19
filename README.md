# FastBVAR

FastBVAR is a small performance and verification layer around the excellent
[BVAR_ toolbox](https://github.com/naffe15/BVAR_) by F. Ferroni and F. Canova.
All credit for the econometric methods, original design, and underlying BVAR
implementation goes to its authors. Please consult and cite their repository
and documentation when using this code.

This repository only contributes a few implementation optimizations and
reference-comparison scripts. It is not a replacement for the original
toolbox. A pinned upstream checkout is retained as the frozen reference, and
the remaining files are limited to the required BVAR runtime, optimized code,
and reproducibility checks.

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

In one local MATLAB R2026a test on an Apple-silicon laptop, the synthetic
`N=7, T=1560, p=52` workload ran roughly 45–50× faster than the frozen
reference. Returned BVAR values matched within the project tolerance of
`1e-6` (observed worst difference below `1.1e-8`). This is only a local
benchmark; results will vary by machine and problem.

The frozen reference is commit
`3975e6597cb23d82e4ebad162af29b2a1105b395` from the original
[Ferroni–Canova BVAR_ repository](https://github.com/naffe15/BVAR_). GPL-3.0
licensing and upstream attribution are retained.
