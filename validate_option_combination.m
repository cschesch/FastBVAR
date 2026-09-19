function report = validate_option_combination(y,lags,options)
%VALIDATE_OPTION_COMBINATION Compare one small configuration with frozen BVAR.

root = fileparts(mfilename('fullpath'));
reference = fullfile(root,'reference','BVAR_');
addpath(root,fullfile(root,'bvartools'));
assert(isfile(fullfile(reference,'bvartools','bvar_.m')), ...
    'Run: git submodule update --init --recursive');
options.verify_mode = true;
warning_state = warning('off','FastBVAR:UnvalidatedCombination');
cleanup = onCleanup(@() warning(warning_state));
tic; expected = run_isolated_bvar(reference,y,lags,options,false); ref_time = toc;
tic; actual = run_isolated_bvar(root,y,lags,options,true); fast_time = toc;
comparison = compare_value(expected,actual,'root',1e-6,1e-6);
signature = fastbvar_option_signature(options);
report = struct('signature',signature,'passed',comparison.passed, ...
    'worst_absolute_difference',comparison.worst_abs, ...
    'worst_path',comparison.worst_path,'reference_seconds',ref_time, ...
    'fast_seconds',fast_time,'message',comparison.message);
if ~comparison.passed
    error('FastBVAR:ExactnessFailure','{%s}: %s',signature,comparison.message);
end
fastbvar_validation_status('register',signature);
fprintf('PASS {%s}: worst %.3g; session marked validated\n', ...
    signature,comparison.worst_abs);
end

function report = compare_value(expected,actual,path_name,abs_tol,rel_tol)
report = struct('passed',true,'message','','worst_abs',0,'worst_path','');
if ~strcmp(class(expected),class(actual)) || ~isequal(size(expected),size(actual))
    report = failure(path_name,'class or size differs',Inf); return;
end
if isstruct(expected)
    a = sort(fieldnames(expected)); b = sort(fieldnames(actual));
    if ~isequal(a,b), report = failure(path_name,'fields differ',Inf); return; end
    for n = 1:numel(expected)
        for i = 1:numel(a)
            child = compare_value(expected(n).(a{i}),actual(n).(a{i}), ...
                sprintf('%s(%d).%s',path_name,n,a{i}),abs_tol,rel_tol);
            report = merge(report,child); if ~report.passed, return; end
        end
    end
elseif iscell(expected)
    for i = 1:numel(expected)
        report = merge(report,compare_value(expected{i},actual{i}, ...
            sprintf('%s{%d}',path_name,i),abs_tol,rel_tol));
        if ~report.passed, return; end
    end
elseif isnumeric(expected) || islogical(expected)
    special = (isnan(expected)&isnan(actual)) | ...
        (isinf(expected)&isinf(actual)&sign(expected)==sign(actual));
    finite = isfinite(expected)&isfinite(actual);
    delta = zeros(size(expected)); delta(finite) = abs(expected(finite)-actual(finite));
    invalid = ~(finite|special) | ...
        (finite & delta > abs_tol+rel_tol.*abs(expected));
    if any(invalid(:)), report = failure(path_name,'values differ', ...
            delta(find(invalid,1))); return; end
    if ~isempty(delta), report.worst_abs=max(delta(:)); report.worst_path=path_name; end
elseif ~isequaln(expected,actual)
    report = failure(path_name,'values differ',Inf);
end
end
function report = failure(path_name,reason,delta)
report=struct('passed',false,'message',sprintf('%s: %s',path_name,reason), ...
    'worst_abs',delta,'worst_path',path_name);
end
function out = merge(left,right)
if ~right.passed || right.worst_abs>left.worst_abs, out=right; else, out=left; end
end
