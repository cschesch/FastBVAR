function results = verify_option_coverage(use_parallel)
%VERIFY_OPTION_COVERAGE Compare every single-option fixture with BVAR.

root = fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'bvartools'));
has_parallel = license('test','Distrib_Computing_Toolbox') ...
    && exist('parpool','file') == 2 && exist('gcp','file') == 2;
if nargin < 1
    use_parallel = has_parallel;
elseif use_parallel && ~has_parallel
    warning('FastBVAR:ParallelUnavailable', ...
        'Parallel Computing Toolbox is unavailable; running serially.');
    use_parallel = false;
end
cases = option_validation_cases();
results = repmat(struct('name','','signature','','passed',false, ...
    'worst_absolute_difference',NaN,'message',''),numel(cases),1);
if use_parallel
    serial_names = {'max_minn_hyper','index_est','max_compute','lb','ub'};
    parallel_indices = find(~ismember({cases.name},serial_names));
    serial_indices = find(ismember({cases.name},serial_names));
    pool = gcp('nocreate');
    if isempty(pool)
        parpool('Processes',4);
    end
    parallel_cases = cases(parallel_indices);
    parallel_results = results(parallel_indices);
    parfor j = 1:numel(parallel_indices)
        parallel_results(j) = run_one(parallel_cases(j));
    end
    results(parallel_indices) = parallel_results;
    for i = serial_indices
        results(i) = run_one(cases(i));
    end
else
    for i = 1:numel(cases)
        results(i) = run_one(cases(i));
    end
end
for i = 1:numel(results)
    if results(i).passed
        fprintf('PASS %-24s {%s} worst %.3g\n',results(i).name, ...
            results(i).signature,results(i).worst_absolute_difference);
    else
        fprintf('FAIL %-24s %s\n',results(i).name,results(i).message);
    end
end
failed = results(~[results.passed]);
if ~isempty(failed)
    error('FastBVAR:OptionCoverageFailure', ...
        '%d option fixtures failed. First: %s',numel(failed),failed(1).message);
end

registry = fastbvar_validation_registry();
covered = {};
for i = 1:numel(cases)
    covered = union(covered,fieldnames(cases(i).options));
end
missing = setdiff(registry.known_fields,union(covered,registry.always_unvalidated));
assert(isempty(missing),'FastBVAR:OptionCoverageMissing', ...
    'No fixture covers: %s',strjoin(missing,', '));
end

function result = run_one(test_case)
result = struct('name',test_case.name,'signature','','passed',false_field(), ...
    'worst_absolute_difference',NaN,'message','');
try
    [~,report] = evalc(['validate_option_combination(test_case.y,' ...
        'test_case.lags,test_case.options)']);
    result.signature = report.signature;
    result.passed = report.passed;
    result.worst_absolute_difference = report.worst_absolute_difference;
catch exception
    result.signature = fastbvar_option_signature(test_case.options);
    result.message = sprintf('%s: %s',exception.identifier,exception.message);
end
end

function value = false_field()
value = false;
end
