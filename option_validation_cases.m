function cases = option_validation_cases()
%OPTION_VALIDATION_CASES One small reference fixture per option branch.

p = benchmark_problem('complete');
base = struct('K',1,'hor',4,'fhor',3,'noprint',true);
y = p.y; lags = p.lags; [T,N] = size(y);
cases = repmat(struct('name','','y',[],'lags',0,'options',struct()),0,1);

add('baseline',y,lags,base);
add('K',y,lags,setfield(base,'K',2)); %#ok<SFLD>
add('hor',y,lags,setfield(base,'hor',5)); %#ok<SFLD>
add('fhor',y,lags,setfield(base,'fhor',4)); %#ok<SFLD>
add('noprint',y,lags,setfield(base,'noprint',false)); %#ok<SFLD>
add('verify_mode',y,lags,setfield(base,'verify_mode',true)); %#ok<SFLD>

addfield('vnames',arrayfun(@(i) sprintf('y%d',i),1:N,'UniformOutput',false));
addfield('firstobs',lags+2);
addfield('presample',1);
addfield('noconstant',1);
addfield('timetrend',1);
addfield('non_explosive_',1);
addfield('heterosked_weights',0.8+0.2*(1:T-lags)'/(T-lags));
addfield('robust_bayes',1);
addfields('robust_bayes_2',{'robust_bayes'},{2});
addfields('K_shrinkage',{'robust_bayes','K_shrinkage'},{1,20});

exo = sin((1:T)'/9);
addfield('exogenous',exo);
addfield('controls',exo);
exo_block = 0.25*y(:,1)+0.5*sin((1:T)'/7)+0.2*cos((1:T)'/3);
addfield('exogenous_block',exo_block);

addfield('prior',struct('name','Minnesota'));
addfield('priors_minnesota',struct('name','Minnesota'),'priors');
q = N*lags+1;
conjugate = struct('name','Conjugate', ...
    'Phi',struct('mean',zeros(q,N),'cov',10*eye(q)), ...
    'Sigma',struct('scale',eye(N),'df',2*N+2));
addfield('priors_conjugate',conjugate,'priors');
plr = struct('name','PLR','PLR',struct('H',eye(N),'phi',ones(N,1)));
addfield('priors_plr',plr,'priors');

addfield('minn_prior_tau',2.5);
addfield('minn_prior_decay',0.7);
addfield('minn_prior_lambda',3);
addfield('minn_prior_mu',1.5);
addfield('minn_prior_omega',1.2);
addfields('bvar_prior_tau',{'bvar_prior_tau','bvar_prior_mu'},{2.5,1.5});
addfields('bvar_prior_decay',{'bvar_prior_decay','bvar_prior_mu'},{0.7,1.5});
addfields('bvar_prior_lambda',{'bvar_prior_lambda','bvar_prior_mu'},{3,1.5});
addfield('bvar_prior_mu',1.5);
addfield('bvar_prior_omega',1.2);
addfield('max_minn_hyper',1);
addfields('index_est',{'max_minn_hyper','index_est','max_compute'}, ...
    {1,1,7});
addfields('max_compute',{'max_minn_hyper','max_compute'},{1,7});
addfields('lb',{'max_minn_hyper','index_est','max_compute','lb'}, ...
    {1,1,2,0.05});
addfields('ub',{'max_minn_hyper','index_est','max_compute','ub'}, ...
    {1,1,2,20});
addfield('pandemic',struct('start',floor(T/2),'h',2,'phi',0.1));

addfield('irf_1STD',0);
addfield('long_run_irf',1);
regimes = zeros(T,1); regimes(floor(T/2)+1:end) = 1;
addfield('heterosked_regimes',regimes);
easy_sign = {'y(1,1,1)>-1e9'};
addfield('signs',easy_sign);
addfield('narrative',{'v([1],1)>-1e9'});
easy_zero = {'y(1,1)=1;'};
addfield('zeros_signs',easy_zero);
addfields('var_pos',{'zeros_signs','var_pos'},{easy_zero,ones(1,N)});
proxy = sin((1:T-lags)'/5)+0.1*cos((1:T-lags)'/3);
addfield('proxy',proxy);
addfields('proxy_end',{'proxy','proxy_end'},{proxy,0});
addfield('hmoments',{'hm(1,1,1)>-1e9'});
addfield('hmoments_eig',4);
addfields('set_irf',{'signs','set_irf'},{easy_sign,1});
addfield('robust_credible_regions',struct('KG',0,'L',2,'gridLength',20));
addfields('robust_signs',{'signs','robust_credible_regions'}, ...
    {easy_sign,struct('KG',1,'L',2,'gridLength',20)});

path = zeros(base.fhor,1);
addfield('endo_path',path);
addfields('endo_index',{'endo_index','endo_path'},{1,path});
addfields('exo_index',{'endo_index','endo_path','exo_index'},{1,path,1});
addfield('Omegaf',eye(N));

pm = benchmark_problem('mixed');
om = base; om.mf_varindex = pm.options.mf_varindex;
add('mf_varindex',pm.y,pm.lags,om);
om = base; om.mixed_freq_index = zeros(size(pm.y,2),1);
om.mixed_freq_index(pm.options.mf_varindex) = 2;
add('mixed_freq_index',pm.y,pm.lags,om);

addfield('nethor',4);
ridge = struct('est',1,'lambda',0.02);
lasso = struct('est',1,'lambda',0.02);
elastic = struct('est',1,'lambda',0.02,'alpha',0.5);
addfields('connectedness',{'connectedness','Ridge','Lasso','ElasticNet'}, ...
    {1,ridge,lasso,elastic});
addfield('Ridge',ridge);
addfield('Lasso',lasso);
addfield('ElasticNet',elastic);

    function addfield(name,value,field_name)
        if nargin < 3, field_name = name; end
        options = base; options.(field_name) = value;
        add(name,y,lags,options);
    end
    function addfields(name,fields,values)
        options = base;
        for j = 1:numel(fields), options.(fields{j}) = values{j}; end
        add(name,y,lags,options);
    end
    function add(name0,y0,lags0,options0)
        cases(end+1,1) = struct('name',name0,'y',y0, ...
            'lags',lags0,'options',options0);
    end
end
