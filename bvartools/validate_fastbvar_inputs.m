function verify_mode = validate_fastbvar_inputs(y,lags,options)
%VALIDATE_FASTBVAR_INPUTS Refuse every unverified FastBVAR configuration.

if ~isnumeric(y) || ~isreal(y) || ndims(y) ~= 2 || isempty(y)
    error('FastBVAR:InvalidData', ...
        'y must be a nonempty real numeric T-by-N matrix.');
end
if any(isinf(y),'all')
    error('FastBVAR:InvalidData','y cannot contain Inf values.');
end
if ~isscalar(lags) || ~isnumeric(lags) || ~isfinite(lags) ...
        || lags < 1 || lags ~= floor(lags)
    error('FastBVAR:InvalidLags', 'lags must be a positive integer scalar.');
end
if ~isstruct(options) || ~isscalar(options)
    error('FastBVAR:InvalidOptions', 'options must be a scalar struct.');
end

allowed = {'K','hor','fhor','noprint','mf_varindex','verify_mode'};
names = fieldnames(options);
unsupported = setdiff(names,allowed);
if ~isempty(unsupported)
    error('FastBVAR:UnsupportedOption', ...
        'Unsupported/unverified option(s): %s',strjoin(unsupported,', '));
end

positive_integers = {'K','hor','fhor'};
for i = 1:numel(positive_integers)
    name = positive_integers{i};
    if isfield(options,name)
        value = options.(name);
        if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) ...
                || value < 1 || value ~= floor(value)
            error('FastBVAR:InvalidOption', ...
                'options.%s must be a positive integer scalar.',name);
        end
    end
end

binary_options = {'noprint','verify_mode'};
for i = 1:numel(binary_options)
    name = binary_options{i};
    if isfield(options,name)
        value = options.(name);
        if ~(islogical(value) || isnumeric(value)) || ~isscalar(value) ...
                || ~isfinite(value) || (value ~= 0 && value ~= 1)
            error('FastBVAR:InvalidOption', ...
                'options.%s must be a logical scalar.',name);
        end
    end
end

has_missing = any(isnan(y),'all');
if isfield(options,'mf_varindex')
    index = options.mf_varindex;
    if ~has_missing
        error('FastBVAR:InvalidOption', ...
            'options.mf_varindex is only valid when y contains NaNs.');
    end
    if ~isnumeric(index) || (~isempty(index) && ~isvector(index)) ...
            || any(~isfinite(index)) ...
            || any(index ~= floor(index)) || any(index < 1) ...
            || any(index > size(y,2)) || numel(unique(index)) ~= numel(index)
        error('FastBVAR:InvalidOption', ...
            'options.mf_varindex must contain unique column indices of y.');
    end
end
if has_missing
    if any(all(isnan(y),2))
        error('FastBVAR:InvalidData', ...
            'Fully missing observation rows have not been verified.');
    end
    finite_per_column = sum(isfinite(y),1);
    if any(finite_per_column < 2)
        error('FastBVAR:InvalidData', ...
            'Every series with missing observations needs at least two finite values.');
    end
end

verify_mode = false;
if isfield(options,'verify_mode')
    verify_mode = logical(options.verify_mode);
end
end
