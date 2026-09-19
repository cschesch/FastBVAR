function signature = fastbvar_option_signature(options)
%FASTBVAR_OPTION_SIGNATURE Canonical non-baseline option-field signature.

registry = fastbvar_validation_registry();
fields = setdiff(fieldnames(options),registry.baseline_fields);
fields = sort(fields);
tokens = cell(size(fields));
for i = 1:numel(fields)
    name = fields{i};
    value = options.(name);
    switch name
        case {'prior','priors'}
            if isstruct(value) && isfield(value,'name')
                tokens{i} = sprintf('%s:%s',name,lower(char(value.name)));
            else
                tokens{i} = name;
            end
        case {'connectedness','hmoments_eig','irf_1STD', ...
                'long_run_irf','max_compute','max_minn_hyper', ...
                'non_explosive_','robust_bayes','set_irf'}
            if isnumeric(value) && isscalar(value) && isfinite(value)
                tokens{i} = sprintf('%s=%g',name,value);
            else
                tokens{i} = name;
            end
        case 'robust_credible_regions'
            if isstruct(value) && isfield(value,'KG') && ...
                    isnumeric(value.KG) && isscalar(value.KG)
                tokens{i} = sprintf('%s:KG=%g',name,value.KG);
            else
                tokens{i} = name;
            end
        otherwise
            tokens{i} = name;
    end
end
if isempty(tokens)
    signature = '<baseline>';
else
    signature = strjoin(tokens,'+');
end
end
