# FastBVAR

FastBVAR is a small set of performance optimizations and verification scripts
for the excellent [BVAR_ toolbox](https://github.com/naffe15/BVAR_) by F.
Ferroni and F. Canova. All credit for the econometric methods, design, and
underlying implementation goes to its authors. Please consult and cite their
repository when using this code.

```bash
git clone --recurse-submodules https://github.com/cschesch/FastBVAR.git
```

```matlab
addpath('FastBVAR','FastBVAR/bvartools')
options = struct('K',1000,'noprint',true);
BVAR = fastbvar_(y,lags,options);
```

All upstream BVAR options are accepted. The included checks compare a small
baseline with every option varied once. Untested combinations emit a warning
and can be checked against the pinned upstream reference with:

```matlab
validate_option_combination(y_small,lags,options)
```

```matlab
verify_exactness          % core modes and p=52 frozen-reference checks
verify_option_coverage    % every one-at-a-time option fixture
compare_timing            % p=13 and p=52 timings
```

In one local MATLAB R2026a test, the synthetic `N=7, T=1560, p=52` workload
ran roughly 45–50× faster while matching returned values within `1e-6`.
Results will vary by machine and problem.

The frozen reference is upstream commit `3975e659`. GPL-3.0 licensing and
attribution are retained.
