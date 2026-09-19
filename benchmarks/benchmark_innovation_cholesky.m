function rows = benchmark_innovation_cholesky(repetitions)
%BENCHMARK_INNOVATION_CHOLESKY Time the cumulative Kalman fast path.
if nargin < 1, repetitions = 5; end
bench_dir = fileparts(mfilename('fullpath'));
root = fileparts(bench_dir);
reference_root = fullfile(root, 'reference', 'BVAR_');
results_dir = fullfile(bench_dir, 'results');
addpath(bench_dir);
addpath(fullfile(root, 'tests'));
specs = {struct('name', 'small_irregular', 'K', 10), ...
         struct('name', 'small_mixed_frequency', 'K', 10), ...
         struct('name', 'small_high_lag', 'K', 5)};
rows = repmat(struct(), numel(specs), 1);
for i = 1:numel(specs)
    problem = generate_benchmark_problem(specs{i}.name);
    problem.options.K = specs{i}.K;
    ref = zeros(repetitions, 1);
    fast = zeros(repetitions, 1);
    run_package_bvar(reference_root, problem.y, problem.lags, ...
        problem.options, false);
    run_package_bvar(root, problem.y, problem.lags, problem.options, true);
    for r = 1:repetitions
        if mod(r, 2)
            ref(r) = time_one(reference_root, problem, false);
            fast(r) = time_one(root, problem, true);
        else
            fast(r) = time_one(root, problem, true);
            ref(r) = time_one(reference_root, problem, false);
        end
    end
    rows(i).case_name = specs{i}.name;
    rows(i).N = problem.spec.N;
    rows(i).T = problem.spec.T;
    rows(i).p = problem.spec.p;
    rows(i).K = specs{i}.K;
    rows(i).state_dimension = problem.state_dimension;
    rows(i).reference_median_seconds = median(ref);
    rows(i).fast_median_seconds = median(fast);
    rows(i).speedup = median(ref) / median(fast);
end
write_csv(fullfile(results_dir, 'innovation_cholesky_matlab.csv'), rows);
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
    'fast_median_seconds,speedup\n']);
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%d,%d,%d,%d,%d,%.9g,%.9g,%.9g\n', ...
        r.case_name, r.N, r.T, r.p, r.K, r.state_dimension, ...
        r.reference_median_seconds, r.fast_median_seconds, r.speedup);
end
end
