function results = verify_exactness()
%VERIFY_EXACTNESS Compare every supported mode with frozen upstream BVAR.

root = fileparts(mfilename('fullpath'));
reference = fullfile(root,'reference','BVAR_');
assert(isfile(fullfile(reference,'bvartools','bvar_.m')), ...
    'Run: git submodule update --init --recursive');
addpath(root,fullfile(root,'bvartools'));

names = {'complete','irregular','mixed','companion','gold_p52'};
results = repmat(struct('case_name','','reference_seconds',0, ...
    'fast_seconds',0,'worst_absolute_difference',0),numel(names),1);
tol = struct('abs_tol',1e-6,'rel_tol',1e-6);
for i = 1:numel(names)
    p = benchmark_problem(names{i});
    if strcmp(names{i},'companion') || strcmp(names{i},'gold_p52')
        p.options.K = 1;
    end
    p.options.verify_mode = true;
    tic;
    expected = run_isolated_bvar(reference,p.y,p.lags,p.options,false);
    reference_seconds = toc;
    tic;
    actual = run_isolated_bvar(root,p.y,p.lags,p.options,true);
    fast_seconds = toc;
    comparison = compare_value(expected,actual,'root',tol);
    assert(comparison.passed,'FastBVAR:ExactnessFailure', ...
        '%s failed: %s',names{i},comparison.message);
    results(i) = struct('case_name',names{i}, ...
        'reference_seconds',reference_seconds,'fast_seconds',fast_seconds, ...
        'worst_absolute_difference',comparison.worst_abs);
    fprintf('PASS %-10s worst %.3g  %.2fx faster\n',names{i}, ...
        comparison.worst_abs,reference_seconds/fast_seconds);
end

verify_singular_fallback(root,reference);
verify_lyapunov(root);

bad = struct('K',1,'not_a_bvar_option',true);
try
    run_isolated_bvar(root,ones(40,2),2,bad,true);
    error('FastBVAR:GuardFailure','Unknown option was accepted.');
catch exception
    assert(strcmp(exception.identifier,'FastBVAR:UnsupportedOption'), ...
        'Unexpected guard error: %s',exception.message);
end
fprintf('PASS option guard (unknown options are refused)\n');

warning_state = warning('query','FastBVAR:UnvalidatedCombination');
warning('on','FastBVAR:UnvalidatedCombination');
lastwarn('');
combo = struct('K',1,'noprint',true,'timetrend',1, ...
    'exogenous',sin((1:40)'/7));
validate_fastbvar_inputs(ones(40,2),2,combo);
[~,warning_id] = lastwarn;
warning(warning_state.state,'FastBVAR:UnvalidatedCombination');
assert(strcmp(warning_id,'FastBVAR:UnvalidatedCombination'), ...
    'FastBVAR:GuardFailure','Unvalidated combination did not warn.');
fprintf('PASS validation registry (untested combinations warn)\n');
end

function verify_singular_fallback(root,reference)
G = diag([0.8 0.7 0.6 0.5]); sig = eye(4); M = 0.1*eye(4);
H = [1 0 0 0; 1 0 0 0]; y = [0.2; 0.2];
shat = [0.1; -0.1; 0.05; 0];
expected = invoke_kf(reference,y,H,shat,sig,G,M);
actual = invoke_kf(root,y,H,shat,sig,G,M);
comparison = compare_value(expected,actual,'kf_dk', ...
    struct('abs_tol',0,'rel_tol',0));
assert(comparison.passed,'FastBVAR:FallbackFailure',comparison.message);
fprintf('PASS singular innovation fallback (bitwise)\n');
end

function output = invoke_kf(package_root,y,H,shat,sig,G,M)
old_path = path; cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
clear('kf_dk'); addpath(fullfile(package_root,'bvartools'),'-begin');
output = cell(1,7); [output{:}] = kf_dk(y,H,shat,sig,G,M);
clear('kf_dk');
end

function verify_lyapunov(root)
old_path = path; cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
addpath(fullfile(root,'bvartools'),'-begin');
A = diag([0.92 0.80 0.55]); B = [1 .1 0; .1 .8 .05; 0 .05 .6];
legacy = lyapunov_symm(A,B); [fast,used_fast] = lyapunov_fast(A,B);
comparison = compare_value(legacy,fast,'lyapunov', ...
    struct('abs_tol',1e-10,'rel_tol',1e-10));
assert(used_fast && comparison.passed,'FastBVAR:LyapunovMismatch', ...
    comparison.message);
A = 1.01*eye(2); B = eye(2); legacy = lyapunov_symm(A,B);
[fallback,used_fast] = lyapunov_fast(A,B);
assert(~used_fast && isequaln(legacy,fallback), ...
    'FastBVAR:LyapunovFallbackFailure','Legacy fallback differs.');
fprintf('PASS Lyapunov fast solve and fallback\n');
end

function report = compare_value(expected,actual,path_name,tol)
report = pass_report();
if ~strcmp(class(expected),class(actual)) || ~isequal(size(expected),size(actual))
    report = fail_report(path_name,'class or size differs',Inf);
elseif isstruct(expected)
    a = sort(fieldnames(expected)); b = sort(fieldnames(actual));
    if ~isequal(a,b), report = fail_report(path_name,'fields differ',Inf); return; end
    for n = 1:numel(expected)
        for i = 1:numel(a)
            child = compare_value(expected(n).(a{i}),actual(n).(a{i}), ...
                sprintf('%s(%d).%s',path_name,n,a{i}),tol);
            report = merge_report(report,child);
            if ~report.passed, return; end
        end
    end
elseif iscell(expected)
    for i = 1:numel(expected)
        report = merge_report(report,compare_value(expected{i},actual{i}, ...
            sprintf('%s{%d}',path_name,i),tol));
        if ~report.passed, return; end
    end
elseif isnumeric(expected) || islogical(expected)
    same_special = (isnan(expected)&isnan(actual)) | ...
        (isinf(expected)&isinf(actual)&sign(expected)==sign(actual));
    finite = isfinite(expected)&isfinite(actual);
    delta = zeros(size(expected)); delta(finite) = abs(expected(finite)-actual(finite));
    invalid = ~(finite|same_special) | ...
        (finite & delta > tol.abs_tol+tol.rel_tol.*abs(expected));
    if any(invalid(:)), report = fail_report(path_name,'values differ', ...
            delta(find(invalid,1))); return; end
    if ~isempty(delta), report.worst_abs = max(delta(:)); report.worst_path = path_name; end
elseif ~isequaln(expected,actual)
    report = fail_report(path_name,'values differ',Inf);
end
end

function report = pass_report()
report = struct('passed',true,'message','','worst_abs',0,'worst_path','');
end
function report = fail_report(path_name,reason,delta)
report = struct('passed',false,'message',sprintf('%s: %s',path_name,reason), ...
    'worst_abs',delta,'worst_path',path_name);
end
function report = merge_report(left,right)
if ~right.passed || right.worst_abs > left.worst_abs, report = right; else, report = left; end
end
