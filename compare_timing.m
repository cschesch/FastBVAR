function results = compare_timing(reference_repetitions,fast_repetitions)
%COMPARE_TIMING Time frozen BVAR and FastBVAR on the two target workloads.

if nargin < 1, reference_repetitions = 1; end
if nargin < 2, fast_repetitions = 5; end
root = fileparts(mfilename('fullpath'));
reference = fullfile(root,'reference','BVAR_');
addpath(root);
names = {'gold_p13','gold_p52'};
results = repmat(struct(),numel(names),1);
for c = 1:numel(names)
    p = benchmark_problem(names{c});
    p.options.K = 1;
    p.options.verify_mode = false;
    run_isolated_bvar(root,p.y,p.lags,p.options,true); % JIT warm-up
    reference_times = zeros(reference_repetitions,1);
    fast_times = zeros(fast_repetitions,1);
    for i = 1:reference_repetitions
        tic; run_isolated_bvar(reference,p.y,p.lags,p.options,false); ...
            reference_times(i) = toc;
    end
    for i = 1:fast_repetitions
        tic; run_isolated_bvar(root,p.y,p.lags,p.options,true); ...
            fast_times(i) = toc;
    end
    results(c).case_name = names{c};
    results(c).reference_median_seconds = median(reference_times);
    results(c).fast_median_seconds = median(fast_times);
    results(c).speedup = median(reference_times)/median(fast_times);
    fprintf('%-10s reference %.3fs  FastBVAR %.3fs  %.2fx\n',names{c}, ...
        results(c).reference_median_seconds, ...
        results(c).fast_median_seconds,results(c).speedup);
end
end
