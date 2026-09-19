function rows = run_baseline_benchmarks()
%RUN_BASELINE_BENCHMARKS Profile the untouched frozen implementation.

bench_dir = fileparts(mfilename('fullpath'));
root = fileparts(bench_dir);
tests_dir = fullfile(root, 'tests');
reference_root = fullfile(root, 'reference', 'BVAR_');
results_dir = fullfile(bench_dir, 'results');
if ~exist(results_dir, 'dir'), mkdir(results_dir); end
addpath(bench_dir);
addpath(tests_dir);

specs = {struct('name', 'small_irregular', 'K', 2), ...
         struct('name', 'small_mixed_frequency', 'K', 2), ...
         struct('name', 'small_high_lag', 'K', 1)};
rows = repmat(empty_row(), numel(specs), 1);
if exist('OCTAVE_VERSION', 'builtin')
    engine_tag = 'octave';
else
    engine_tag = 'matlab';
end

for i = 1:numel(specs)
    problem = generate_benchmark_problem(specs{i}.name);
    problem.options.K = specs{i}.K;
    profile clear;
    profile on;
    t0 = tic;
    output = run_package_bvar(reference_root, problem.y, problem.lags, ...
        problem.options, false);
    elapsed = toc(t0);
    profile off;
    info = profile('info');

    rows(i) = make_row(problem, specs{i}.K, elapsed, output);
    write_profile_csv(fullfile(results_dir, ...
        [specs{i}.name '_' engine_tag '_profile.csv']), info);
    fprintf('%-24s %.3fs (%d draws, state %d)\n', specs{i}.name, ...
        elapsed, specs{i}.K, problem.state_dimension);
end

save(fullfile(results_dir, ['baseline_' engine_tag '.mat']), 'rows');
write_summary_csv(fullfile(results_dir, ...
    ['baseline_' engine_tag '_summary.csv']), rows);
end

function row = empty_row()
row = struct('case_name', '', 'engine', '', 'engine_version', '', ...
    'upstream_commit', '3975e6597cb23d82e4ebad162af29b2a1105b395', ...
    'N', 0, 'T', 0, 'p', 0, 'K', 0, 'state_dimension', 0, ...
    'design_regressors', 0, 'wall_seconds', 0, 'seconds_per_draw', 0, ...
    'output_bytes', 0, 'peak_memory_bytes', NaN);
end

function row = make_row(problem, K, elapsed, output)
row = empty_row();
row.case_name = problem.name;
if exist('OCTAVE_VERSION', 'builtin')
    row.engine = 'GNU Octave';
    row.engine_version = OCTAVE_VERSION;
else
    row.engine = 'MATLAB';
    row.engine_version = version;
end
row.N = problem.spec.N;
row.T = problem.spec.T;
row.p = problem.spec.p;
row.K = K;
row.state_dimension = problem.state_dimension;
row.design_regressors = problem.design_regressors;
row.wall_seconds = elapsed;
row.seconds_per_draw = elapsed / K;
details = whos('output');
row.output_bytes = details.bytes;
end

function write_summary_csv(filename, rows)
fid = fopen(filename, 'w');
assert(fid >= 0, 'Cannot open %s', filename);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, ['case,engine,engine_version,commit,N,T,p,K,state_dimension,' ...
    'design_regressors,wall_seconds,seconds_per_draw,output_bytes,' ...
    'peak_memory_bytes\n']);
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid, '%s,%s,%s,%s,%d,%d,%d,%d,%d,%d,%.9g,%.9g,%d,%.9g\n', ...
        r.case_name, r.engine, r.engine_version, r.upstream_commit, ...
        r.N, r.T, r.p, r.K, r.state_dimension, r.design_regressors, ...
        r.wall_seconds, r.seconds_per_draw, r.output_bytes, ...
        r.peak_memory_bytes);
end
end

function write_profile_csv(filename, info)
fid = fopen(filename, 'w');
assert(fid >= 0, 'Cannot open %s', filename);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'function,total_seconds,calls\n');
table_data = info.FunctionTable;
for i = 1:numel(table_data)
    item = table_data(i);
    name = strrep(item.FunctionName, ',', '_');
    fprintf(fid, '%s,%.9g,%d\n', name, item.TotalTime, item.NumCalls);
end
end
