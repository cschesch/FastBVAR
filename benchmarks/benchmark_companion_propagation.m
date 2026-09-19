function rows = benchmark_companion_propagation()
%BENCHMARK_COMPANION_PROPAGATION Locate dense/block propagation crossover.
N = 7;
lags = [8 13 20 26 52];
rows = repmat(struct(), numel(lags), 1);
rng(4401, 'twister');
for i = 1:numel(lags)
    ns = N*lags(i);
    G = [0.03*randn(N,ns); eye(ns-N,ns)];
    raw = randn(ns,ns);
    P = raw*raw'/ns;
    M = [eye(N); zeros(ns-N,N)];
    dense_seconds = timeit(@() dense_one(G,P,M));
    block_seconds = timeit(@() block_one(G,P,M,N));
    rows(i).N = N;
    rows(i).p = lags(i);
    rows(i).state_dimension = ns;
    rows(i).dense_seconds = dense_seconds;
    rows(i).block_seconds = block_seconds;
    rows(i).speedup = dense_seconds/block_seconds;
end

bench_dir = fileparts(mfilename('fullpath'));
filename = fullfile(bench_dir,'results','companion_propagation_matlab.csv');
fid = fopen(filename,'w');
assert(fid >= 0, 'Cannot open %s',filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'N,p,state_dimension,dense_seconds,block_seconds,speedup\n');
for i = 1:numel(rows)
    r = rows(i);
    fprintf(fid,'%d,%d,%d,%.9g,%.9g,%.9g\n',r.N,r.p,r.state_dimension, ...
        r.dense_seconds,r.block_seconds,r.speedup);
end
end

function omega = dense_one(G,P,M)
omega = G*P*G'+M*M';
end

function omega = block_one(G,P,M,N)
ns = size(G,1);
nshift = ns-N;
AP = G(1:N,:)*P;
omega = zeros(ns,ns);
omega(1:N,1:N) = AP*G(1:N,:)' + M(1:N,:)*M(1:N,:)';
omega(1:N,N+1:end) = AP(:,1:nshift);
omega(N+1:end,1:N) = AP(:,1:nshift)';
omega(N+1:end,N+1:end) = P(1:nshift,1:nshift);
end
