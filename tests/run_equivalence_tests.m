function results = run_equivalence_tests()
%RUN_EQUIVALENCE_TESTS Compare FastBVAR with the frozen upstream checkout.

tests_dir = fileparts(mfilename('fullpath'));
root = fileparts(tests_dir);
addpath(tests_dir);
addpath(fullfile(root, 'benchmarks'));

reference_root = fullfile(root, 'reference', 'BVAR_');
assert(exist(fullfile(reference_root, 'bvartools', 'bvar_.m'), 'file') == 2, ...
    ['Reference submodule is missing. Run: git submodule update --init ' ...
     '--recursive']);

specs = { ...
    struct('name', 'small_complete', 'K', 3), ...
    struct('name', 'small_irregular', 'K', 2), ...
    struct('name', 'small_mixed_frequency', 'K', 2)};

results = repmat(struct('name', '', 'passed', false, 'seconds_reference', 0, ...
    'seconds_fast', 0, 'comparison', struct()), numel(specs), 1);

for i = 1:numel(specs)
    spec = specs{i};
    problem = generate_benchmark_problem(spec.name);
    problem.options.K = spec.K;
    problem.options.noprint = 1;

    t0 = tic;
    reference = run_package_bvar(reference_root, problem.y, ...
        problem.lags, problem.options, false);
    reference_seconds = toc(t0);

    t0 = tic;
    fast = run_package_bvar(root, problem.y, problem.lags, ...
        problem.options, true);
    fast_seconds = toc(t0);

    comparison = compare_recursive(reference, fast, ...
        struct('abs_tol', 0, 'rel_tol', 0));
    results(i).name = spec.name;
    results(i).passed = comparison.passed;
    results(i).seconds_reference = reference_seconds;
    results(i).seconds_fast = fast_seconds;
    results(i).comparison = comparison;

    if ~comparison.passed
        error('FastBVAR:EquivalenceFailure', ...
            'FAIL %s: %s', spec.name, comparison.message);
    end
    fprintf('PASS %-24s reference %.3fs, fast %.3fs (bitwise)\n', ...
        spec.name, reference_seconds, fast_seconds);
end

fprintf('PASS all %d equivalence tests.\n', numel(results));
end

