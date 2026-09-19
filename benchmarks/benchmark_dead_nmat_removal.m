function rows = benchmark_dead_nmat_removal(repetitions)
%BENCHMARK_DEAD_NMAT_REMOVAL Benchmark the first exact memory optimization.
if nargin < 1, repetitions = 5; end

bench_dir = fileparts(mfilename('fullpath'));
root = fileparts(bench_dir);
reference_root = fullfile(root, 'reference', 'BVAR_');
results_dir = fullfile(bench_dir, 'results');
addpath(bench_dir);
addpath(fullfile(root, 'tests'));
if ~exist(results_dir, 'dir'), mkdir(results_dir); end

specs = {struct('name', 'small_irregular', 'K', 2), ...
         struct('name', 'small_high_lag', 'K', 1)};
rows = repmat(struct(), numel(specs), 1);

for i = 1:numel(specs)
    problem = generate_benchmark_problem(specs{i}.name);
    problem.options.K = specs{i}.K;
    reference_times = zeros(repetitions, 1);
    fast_times = zeros(repetitions, 1);

    % One untimed run per implementation warms MATLAB's JIT and BLAS paths.
    run_package_bvar(reference_root, problem.y, problem.lags, ...
        problem.options, false);
    run_package_bvar(root, problem.y, problem.lags, problem.options, true);

    for r = 1:repetitions
        if mod(r, 2)
            reference_times(r) = time_one(reference_root, problem, false);
            fast_times(r) = time_one(root, problem, true);
        else
            fast_times(r) = time_one(root, problem, true);
            reference_times(r) = time_one(reference_root, problem, false);
        end
    end

    rows(i).case_name = specs{i}.name;
    rows(i).N = problem.spec.N;
    rows(i).T = problem.spec.T;
    rows(i).p = problem.spec.p;
    rows(i).K = specs{i}.K;
    rows(i).state_dimension = problem.state_dimension;
    rows(i).reference_median_seconds = median(reference_times);
    rows(i).fast_median_seconds = median(fast_times);
    rows(i).speedup = rows(i).reference_median_seconds / ...
        rows(i).fast_median_seconds;
    rows(i).bytes_removed_per_kalman_call = ...
        8 * problem.state_dimension^2 * problem.spec.T;
end

write_csv(fullfile(results_dir, 'dead_nmat_matlab.csv'), rows);
end

function seconds = time_one(package_root, problem, use_alias)
t0 = tic;
run_package_bvar(package_root, problem.y, problem.lags, ...
    problem.options, use_alias);
seconds = toc(t0);
end

function write_csv(filename, rows)
fid = fopen(filename, 'w');
assert(fid >= 0, 'Cannot open %s', filename);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, ['case,N,T,p,K,state_dimension,reference_median_seconds,' ...
    'fast_median_seconds,speedup,bytes_removed_per_kalman_call\n']);
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%d,%d,%d,%d,%d,%.9g,%.9g,%.9g,%d\n', ...
        r.case_name, r.N, r.T, r.p, r.K, r.state_dimension, ...
        r.reference_median_seconds, r.fast_median_seconds, r.speedup, ...
        r.bytes_removed_per_kalman_call);
end
end
