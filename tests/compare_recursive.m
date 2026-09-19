function report = compare_recursive(expected, actual, tolerances)
%COMPARE_RECURSIVE Strict recursive comparator for MATLAB result objects.
%   Numeric values pass when abs(a-b) <= abs_tol + rel_tol*abs(expected).

if nargin < 3
    tolerances = struct();
end
if ~isfield(tolerances, 'abs_tol'), tolerances.abs_tol = 0; end
if ~isfield(tolerances, 'rel_tol'), tolerances.rel_tol = 0; end

report = compare_value(expected, actual, 'root', tolerances);
end

function report = compare_value(expected, actual, field_path, tol)
report = pass_report();
if ~strcmp(class(expected), class(actual))
    report = fail_report(field_path, sprintf('class %s ~= %s', ...
        class(expected), class(actual)), Inf, []);
    return;
end
if ~isequal(size(expected), size(actual))
    report = fail_report(field_path, sprintf('size %s ~= %s', ...
        mat2str(size(expected)), mat2str(size(actual))), Inf, []);
    return;
end

if isstruct(expected)
    expected_fields = sort(fieldnames(expected));
    actual_fields = sort(fieldnames(actual));
    if ~isequal(expected_fields, actual_fields)
        report = fail_report(field_path, 'field names differ', Inf, []);
        return;
    end
    for n = 1:numel(expected)
        for i = 1:numel(expected_fields)
            name = expected_fields{i};
            child_path = sprintf('%s(%d).%s', field_path, n, name);
            child = compare_value(expected(n).(name), actual(n).(name), ...
                child_path, tol);
            report = merge_report(report, child);
            if ~report.passed, return; end
        end
    end
elseif iscell(expected)
    for i = 1:numel(expected)
        child = compare_value(expected{i}, actual{i}, ...
            sprintf('%s{%d}', field_path, i), tol);
        report = merge_report(report, child);
        if ~report.passed, return; end
    end
elseif isnumeric(expected) || islogical(expected)
    nan_match = isnan(expected) & isnan(actual);
    finite_match = isfinite(expected) & isfinite(actual);
    special_match = (isinf(expected) & isinf(actual) & ...
        sign(expected) == sign(actual)) | nan_match;
    invalid = ~(finite_match | special_match);
    discrepancy = zeros(size(expected));
    discrepancy(finite_match) = abs(expected(finite_match) - actual(finite_match));
    allowed = tol.abs_tol + tol.rel_tol .* abs(expected);
    invalid = invalid | (finite_match & discrepancy > allowed);
    if any(invalid(:))
        index = find(invalid, 1, 'first');
        report = fail_report(field_path, 'numeric values differ', ...
            discrepancy(index), index);
        return;
    end
    if ~isempty(discrepancy)
        [report.worst_abs, report.worst_index] = max(discrepancy(:));
        report.worst_path = field_path;
    end
elseif ischar(expected) || isstring(expected)
    if ~isequal(expected, actual)
        report = fail_report(field_path, 'text differs', Inf, []);
    end
else
    if ~isequaln(expected, actual)
        report = fail_report(field_path, 'values differ', Inf, []);
    end
end
end

function report = pass_report()
report = struct('passed', true, 'message', '', 'worst_abs', 0, ...
    'worst_path', '', 'worst_index', []);
end

function report = fail_report(path_name, reason, discrepancy, index)
report = struct('passed', false, ...
    'message', sprintf('%s: %s', path_name, reason), ...
    'worst_abs', discrepancy, 'worst_path', path_name, ...
    'worst_index', index);
end

function out = merge_report(left, right)
if ~right.passed
    out = right;
elseif right.worst_abs > left.worst_abs
    out = right;
else
    out = left;
end
end

