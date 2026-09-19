# Phase-1 baseline results

`baseline_summary.csv` and the three original `*_profile.csv` files were generated from
the untouched reference submodule at commit
`3975e6597cb23d82e4ebad162af29b2a1105b395` using GNU Octave 9.4.0.

The `.mat` output is intentionally ignored because it is engine-specific and
can be regenerated with `run_baseline_benchmarks`.

New runs use engine-qualified names such as `baseline_matlab_summary.csv` and
`small_irregular_matlab_profile.csv`, preventing one engine from overwriting
another.
