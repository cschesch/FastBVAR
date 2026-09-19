# Compatibility matrix

Status values are also available from `fastbvar_capabilities`.

| Option / feature | Fast path | Reference fallback | Tested | Notes |
| --- | --- | --- | --- | --- |
| Default estimation and outputs | No | Yes (in-tree legacy code) | Yes | Bitwise Phase-1 comparison |
| Irregular missing observations | No | Yes | Yes | Stock convention, fixed masks |
| Mixed-frequency flow aggregation (`mf_varindex`) | No | Yes | Yes | Quarterly 3-month averages |
| Minnesota and conjugate priors | No | In-tree legacy code | Not yet | Explicitly unvalidated |
| Forecasts and Cholesky IRFs | No | In-tree legacy code | Only as fields in tests above | Dedicated option tests pending |
| Other identification schemes | No | In-tree legacy code | Not yet | No equivalence claim |
| Panels, FAVAR, robust/penalized paths | No | In-tree legacy code | Not yet | No equivalence claim |

Phase 1 intentionally contains no optimized numerical path. Unvalidated
options retain the upstream behavior when calling `bvar_`, but FastBVAR does
not yet claim independent validation for them.

