function test_rng_optout(root,reference_root)
%TEST_RNG_OPTOUT Check opt-out correctness for a one-draw result.
problem = generate_benchmark_problem('small_irregular');
problem.options.K = 1;
problem.options.preserve_rng = false;
reference = run_package_bvar(reference_root,problem.y,problem.lags, ...
    problem.options,false);
reference_next = randn;
fast = run_package_bvar(root,problem.y,problem.lags,problem.options,true);
fast_next = randn;
comparison = compare_recursive(reference,fast, ...
    struct('abs_tol',1e-6,'rel_tol',1e-6));
assert(comparison.passed,'FastBVAR:RngOptoutMismatch',comparison.message);
assert(reference_next ~= fast_next,'FastBVAR:RngOptoutInactive', ...
    'preserve_rng=false did not change post-call RNG positioning.');
fprintf('PASS %-24s (one-draw output; stream opt-out active)\n', ...
    'rng_optout');
end
