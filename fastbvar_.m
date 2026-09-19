function BVAR = fastbvar_(y, lags, options)
%FASTBVAR_ Explicit FastBVAR entry point.
%   Supports only the validated option surface documented in README.md.
%   Set options.verify_mode=true to preserve the frozen BVAR RNG stream.

if nargin < 3
    BVAR = bvar_(y, lags);
else
    BVAR = bvar_(y, lags, options);
end
end
