function test_lyapunov_fast(root)
%TEST_LYAPUNOV_FAST Check doubling accuracy and legacy fallback.
old_path = path;
cleanup = onCleanup(@() path(old_path));
addpath(fullfile(root,'bvartools'),'-begin');

A = diag([0.92 0.80 0.55]);
B = [1 .1 0; .1 .8 .05; 0 .05 .6];
legacy = lyapunov_symm(A,B);
[fast,used_fast] = lyapunov_fast(A,B);
assert(used_fast,'FastBVAR:LyapunovFastNotUsed', ...
    'Stable test problem unexpectedly used the legacy solver.');
comparison = compare_recursive(legacy,fast, ...
    struct('abs_tol',1e-10,'rel_tol',1e-10));
assert(comparison.passed,'FastBVAR:LyapunovMismatch',comparison.message);

A = 1.01*eye(2);
B = eye(2);
legacy = lyapunov_symm(A,B);
[fallback,used_fast] = lyapunov_fast(A,B);
assert(~used_fast && isequaln(legacy,fallback), ...
    'FastBVAR:LyapunovFallbackFailure', ...
    'Nonconvergent doubling case did not use the exact legacy fallback.');
fprintf('PASS %-24s (fast solve and bitwise fallback)\n','lyapunov_fast');
end
