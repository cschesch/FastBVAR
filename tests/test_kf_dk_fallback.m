function test_kf_dk_fallback(root, reference_root)
%TEST_KF_DK_FALLBACK Verify singular innovations use the legacy SVD exactly.

G = diag([0.8 0.7 0.6 0.5]);
sig = eye(4);
M = 0.1*eye(4);
H = [1 0 0 0; 1 0 0 0]; % deliberately rank deficient
y = [0.2; 0.2];
shat = [0.1; -0.1; 0.05; 0];

reference = invoke(reference_root, y, H, shat, sig, G, M);
fast = invoke(root, y, H, shat, sig, G, M);
comparison = compare_recursive(reference, fast, ...
    struct('abs_tol', 0, 'rel_tol', 0));
assert(comparison.passed, 'FastBVAR:FallbackFailure', ...
    'Singular kf_dk fallback differs: %s', comparison.message);
fprintf('PASS %-24s (bitwise legacy SVD fallback)\n', 'kf_dk_singular');
end

function output = invoke(package_root, y, H, shat, sig, G, M)
old_path = path;
cleanup = onCleanup(@() path(old_path));
clear('kf_dk');
addpath(fullfile(package_root, 'bvartools'), '-begin');
output = cell(1, 7);
[output{:}] = kf_dk(y, H, shat, sig, G, M);
clear('kf_dk');
end
