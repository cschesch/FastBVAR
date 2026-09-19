function results = run_large_benchmarks(K)
%RUN_LARGE_BENCHMARKS Large-stage driver; run only after small tests pass.
if nargin < 1, K = 5; end
run_equivalence_tests();
names = {'gold_p13', 'gold_p52', 'fiscal_monetary'};
results = struct();
for i = 1:numel(names)
    problem = generate_benchmark_problem(names{i});
    problem.options.K = K;
    t0 = tic;
    result = bvar_(problem.y, problem.lags, problem.options);
    results.(names{i}).wall_seconds = toc(t0);
    results.(names{i}).seconds_per_draw = ...
        results.(names{i}).wall_seconds / K;
    results.(names{i}).dimensions = [problem.spec.N, problem.spec.T, ...
        problem.spec.p, problem.state_dimension];
    clear result;
end
end

