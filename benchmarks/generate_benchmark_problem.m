function problem = generate_benchmark_problem(name)
%GENERATE_BENCHMARK_PROBLEM Deterministic FastBVAR synthetic benchmarks.

switch lower(name)
    case 'small_complete'
        spec = struct('N', 4, 'T', 180, 'p', 4, 'seed', 1101, ...
            'kind', 'complete', 'missing_rate', 0);
    case 'small_irregular'
        spec = struct('N', 5, 'T', 180, 'p', 6, 'seed', 1102, ...
            'kind', 'irregular', 'missing_rate', 0.075);
    case 'small_high_lag'
        spec = struct('N', 4, 'T', 300, 'p', 16, 'seed', 1103, ...
            'kind', 'irregular', 'missing_rate', 0.05);
    case 'small_mixed_frequency'
        spec = struct('N', 6, 'T', 150, 'p', 6, 'seed', 1104, ...
            'kind', 'mixed', 'quarterly', [1 2], 'early_missing', 6);
    case 'gold_p13'
        spec = struct('N', 7, 'T', 1560, 'p', 13, 'seed', 2101, ...
            'kind', 'irregular', 'missing_rate', 0.075);
    case 'gold_p52'
        spec = struct('N', 7, 'T', 1560, 'p', 52, 'seed', 2102, ...
            'kind', 'irregular', 'missing_rate', 0.075);
    case 'fiscal_monetary'
        spec = struct('N', 9, 'T', 612, 'p', 12, 'seed', 2103, ...
            'kind', 'mixed', 'quarterly', 1:5, 'early_missing', 48);
    otherwise
        error('FastBVAR:UnknownBenchmark', 'Unknown benchmark: %s', name);
end

set_seed(spec.seed);
[latent, coefficients, sigma] = simulate_stable_var(spec.T, spec.N, spec.p);
y = latent;
options = struct('K', 5, 'noprint', 1, 'hor', 12, 'fhor', 6);

if strcmp(spec.kind, 'irregular')
    eligible = false(spec.T, spec.N);
    eligible(spec.p + 8:end - 3, :) = true;
    mask = rand(spec.T, spec.N) < spec.missing_rate & eligible;
    y(mask) = NaN;
elseif strcmp(spec.kind, 'mixed')
    quarterly = spec.quarterly;
    for j = quarterly
        flow = filter(ones(3, 1) / 3, 1, latent(:, j));
        y(:, j) = NaN;
        observed = 3:3:spec.T;
        y(observed, j) = flow(observed);
    end
    monthly_with_late_start = spec.N;
    y(1:spec.early_missing, monthly_with_late_start) = NaN;
    options.mf_varindex = quarterly;
end

problem = struct('name', name, 'y', y, 'latent', latent, ...
    'lags', spec.p, 'options', options, 'spec', spec, ...
    'true_coefficients', coefficients, 'true_sigma', sigma, ...
    'state_dimension', spec.N * spec.p, ...
    'design_regressors', spec.N * spec.p + 1);
end

function [y, A, sigma] = simulate_stable_var(T, N, p)
burn = 200;
A = zeros(N, N, p);
A(:, :, 1) = 0.42 * eye(N);
if p >= 2, A(:, :, 2) = -0.12 * eye(N); end
for lag = 3:p
    A(:, :, lag) = (0.025 / lag) * eye(N);
end
for i = 1:N
    j = mod(i, N) + 1;
    A(i, j, 1) = 0.035;
end
sigma = 0.15 * eye(N) + 0.02 * ones(N);
shock_chol = chol(sigma, 'lower');
y = zeros(T + burn, N);
shocks = randn(T + burn, N) * shock_chol';
for t = p + 1:T + burn
    value = zeros(1, N);
    for lag = 1:p
        value = value + y(t - lag, :) * A(:, :, lag)';
    end
    y(t, :) = value + shocks(t, :);
end
y = y(burn + 1:end, :);
end

function set_seed(seed)
if exist('OCTAVE_VERSION', 'builtin')
    rand('state', seed); %#ok<RAND>
    randn('state', seed); %#ok<RAND>
else
    rng(seed, 'twister');
end
end

