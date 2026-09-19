function results = run_large_benchmarks(K, names)
%RUN_LARGE_BENCHMARKS Compare frozen reference and FastBVAR large cases.
if nargin < 1, K = 1; end
if nargin < 2, names = {'gold_p13', 'gold_p52', 'fiscal_monetary'}; end

bench_dir = fileparts(mfilename('fullpath'));
root = fileparts(bench_dir);
reference_root = fullfile(root, 'reference', 'BVAR_');
results_dir = fullfile(bench_dir, 'results');
addpath(bench_dir);
addpath(fullfile(root, 'tests'));
run_equivalence_tests();

results = repmat(struct(), numel(names), 1);
for i = 1:numel(names)
    problem = generate_benchmark_problem(names{i});
    problem.options.K = K;
    problem.options.noprint = 1;

    t0 = tic;
    run_package_bvar(reference_root, problem.y, problem.lags, ...
        problem.options, false);
    reference_seconds = toc(t0);
    t0 = tic;
    run_package_bvar(root, problem.y, problem.lags, ...
        problem.options, true);
    fast_seconds = toc(t0);

    results(i).case_name = names{i};
    results(i).N = problem.spec.N;
    results(i).T = problem.spec.T;
    results(i).p = problem.spec.p;
    results(i).K = K;
    results(i).state_dimension = problem.state_dimension;
    results(i).reference_seconds = reference_seconds;
    results(i).fast_seconds = fast_seconds;
    results(i).speedup = reference_seconds / fast_seconds;
    results(i).dead_bytes_removed_per_call = ...
        8 * problem.state_dimension^2 * problem.spec.T;
    fprintf('%-20s reference %.3fs fast %.3fs speedup %.2fx\n', ...
        names{i}, reference_seconds, fast_seconds, results(i).speedup);
end
write_csv(fullfile(results_dir, 'large_matlab.csv'), results);
end

function write_csv(filename, rows)
fid = fopen(filename, 'w');
assert(fid >= 0, 'Cannot open %s', filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, ['case,N,T,p,K,state_dimension,reference_seconds,fast_seconds,' ...
    'speedup,dead_bytes_removed_per_call\n']);
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%d,%d,%d,%d,%d,%.9g,%.9g,%.9g,%d\n', ...
        r.case_name, r.N, r.T, r.p, r.K, r.state_dimension, ...
        r.reference_seconds, r.fast_seconds, r.speedup, ...
        r.dead_bytes_removed_per_call);
end
end
