# FastBVAR

A narrow, faster implementation of the default Ferroni–Canova BVAR, with a
pinned upstream checkout as its reference. The `N=7, T=1560, p=52` synthetic
case runs roughly 25–30× faster in MATLAB R2026a while matching reference outputs
within `1e-6` absolute/relative tolerance.

```bash
git clone --recurse-submodules https://github.com/cschesch/FastBVAR.git
```

```matlab
addpath('FastBVAR','FastBVAR/bvartools')
options = struct('K',1000,'noprint',true);
BVAR = fastbvar_(y,lags,options);
```

Supported options are only `K`, `hor`, `fhor`, `noprint`, `mf_varindex`, and
`verify_mode`; every other option is rejected as unverified. Complete data,
irregular missing stock variables, mixed-frequency flow variables, and the
large companion-state path are covered by `verify_exactness`.

Fast mode skips RNG draws that upstream generates for an unused simulation
output. Set `options.verify_mode=true` to restore upstream stream positioning
for exactness checks.

```matlab
verify_exactness     % frozen-reference comparison of every supported mode
compare_timing       % p=13 and p=52 reference-versus-fast timing
```

The reference is upstream commit
`3975e6597cb23d82e4ebad162af29b2a1105b395`. GPL-3.0 licensing and attribution
are retained.
