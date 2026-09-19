# Compatibility matrix

Status values are also available from `fastbvar_capabilities`.

| Option / feature | Fast path | Reference fallback | Tested | Notes |
| --- | --- | --- | --- | --- |
| Default estimation and outputs | Yes | Yes (in-tree legacy code) | Yes | `1e-6` abs/rel validation contract |
| Irregular missing observations | Yes | Yes | Yes | `1e-6` abs/rel; SVD fallback near singularity |
| Mixed-frequency flow aggregation (`mf_varindex`) | Yes | Yes | Yes | `1e-6` abs/rel; quarterly 3-month averages |
| RNG stream preservation (`preserve_rng`) | Yes | Yes | Yes | Default `true` preserves upstream stream position; `false` skips unused draws |
| Minnesota and conjugate priors | No | In-tree legacy code | Not yet | Explicitly unvalidated |
| Forecasts and Cholesky IRFs | No | In-tree legacy code | Only as fields in tests above | Dedicated option tests pending |
| Other identification schemes | No | In-tree legacy code | Not yet | No equivalence claim |
| Panels, FAVAR, robust/penalized paths | No | In-tree legacy code | Not yet | No equivalence claim |

The optimized path includes observation-dimensional Cholesky updates, a
structured companion covariance propagation for states of dimension 128 or
larger, and a checked doubling solver for the stationary covariance. Each
optimization retains a robust legacy fallback. Unvalidated options retain the
upstream behavior when calling `bvar_`, but FastBVAR does not yet claim
independent validation for them.
