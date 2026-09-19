function BVAR = fastbvar_(y, lags, options)
%FASTBVAR_ Explicit FastBVAR entry point.
%   This Phase-1 wrapper deliberately calls the unchanged upstream bvar_.
%   Optimized dispatch is added only after reference equivalence and baseline
%   profiling have been established.

if nargin < 3
    BVAR = bvar_(y, lags);
else
    BVAR = bvar_(y, lags, options);
end
end

