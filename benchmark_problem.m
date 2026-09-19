function problem = benchmark_problem(name)
%BENCHMARK_PROBLEM Deterministic data shared by verification and timing.

switch lower(name)
    case 'complete'
        s = struct('N',4,'T',180,'p',4,'seed',1101, ...
            'kind','complete','missing_rate',0);
    case 'irregular'
        s = struct('N',5,'T',180,'p',6,'seed',1102, ...
            'kind','irregular','missing_rate',0.075);
    case 'mixed'
        s = struct('N',6,'T',150,'p',6,'seed',1104, ...
            'kind','mixed','quarterly',[1 2],'early_missing',6);
    case 'companion'
        s = struct('N',7,'T',360,'p',20,'seed',1105, ...
            'kind','irregular','missing_rate',0.075);
    case 'gold_p13'
        s = struct('N',7,'T',1560,'p',13,'seed',2101, ...
            'kind','irregular','missing_rate',0.075);
    case 'gold_p52'
        s = struct('N',7,'T',1560,'p',52,'seed',2102, ...
            'kind','irregular','missing_rate',0.075);
    otherwise
        error('FastBVAR:UnknownBenchmark','Unknown benchmark: %s',name);
end

rng(s.seed,'twister');
latent = simulate_var(s.T,s.N,s.p);
y = latent;
options = struct('K',2,'hor',12,'fhor',6,'noprint',true);
if strcmp(s.kind,'irregular')
    eligible = false(s.T,s.N);
    eligible(s.p+8:end-3,:) = true;
    y(rand(s.T,s.N) < s.missing_rate & eligible) = NaN;
    options.mf_varindex = []; % explicitly verified stock-variable mode
elseif strcmp(s.kind,'mixed')
    for j = s.quarterly
        flow = filter(ones(3,1)/3,1,latent(:,j));
        y(:,j) = NaN;
        y(3:3:s.T,j) = flow(3:3:s.T);
    end
    y(1:s.early_missing,s.N) = NaN;
    options.mf_varindex = s.quarterly;
end
problem = struct('name',name,'y',y,'lags',s.p,'options',options, ...
    'N',s.N,'T',s.T,'state_dimension',s.N*s.p);
end

function y = simulate_var(T,N,p)
burn = 200;
A = zeros(N,N,p);
A(:,:,1) = 0.42*eye(N);
if p >= 2, A(:,:,2) = -0.12*eye(N); end
for lag = 3:p, A(:,:,lag) = (0.025/lag)*eye(N); end
for i = 1:N, A(i,mod(i,N)+1,1) = 0.035; end
shock_chol = chol(0.15*eye(N)+0.02*ones(N),'lower');
y = zeros(T+burn,N);
shocks = randn(T+burn,N)*shock_chol';
for t = p+1:T+burn
    for lag = 1:p
        y(t,:) = y(t,:) + y(t-lag,:)*A(:,:,lag)';
    end
    y(t,:) = y(t,:) + shocks(t,:);
end
y = y(burn+1:end,:);
end
