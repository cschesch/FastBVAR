function [x,used_fast] = lyapunov_fast(a,b)
%LYAPUNOV_FAST Solve X-A*X*A'=B by squared Smith iteration.
%   Falls back to the upstream Schur solver if convergence or the residual
%   check is unsatisfactory. No extra MATLAB toolbox is required.

x = b;
apow = a;
used_fast = false;
converged = false;
for iteration = 1:60
    increment = apow*x*apow';
    xnew = x + increment;
    if norm(increment,'fro') <= 1e-12*max(1,norm(xnew,'fro'))
        x = (xnew+xnew')/2;
        converged = true;
        break;
    end
    x = xnew;
    apow = apow*apow;
    if any(~isfinite(apow(:))) || any(~isfinite(x(:)))
        break;
    end
end

if converged
    residual = x-a*x*a'-b;
    scale = max(1,norm(b,'fro') + norm(x,'fro'));
    if norm(residual,'fro') <= 1e-9*scale
        used_fast = true;
        return;
    end
end
x = lyapunov_symm(a,b);
end
