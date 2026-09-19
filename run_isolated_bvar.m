function output = run_isolated_bvar(package_root,y,lags,options,use_fast)
%RUN_ISOLATED_BVAR Run one checkout without MATLAB path leakage.

old_path = path;
cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
clear_package_functions(package_root);
addpath(fullfile(package_root,'bvartools'),'-begin');
cmintools = fullfile(package_root,'cmintools');
if isfolder(cmintools), addpath(cmintools,'-begin'); end
if use_fast
    addpath(package_root,'-begin');
    output = fastbvar_(y,lags,options);
else
    output = bvar_(y,lags,options);
end
clear_package_functions(package_root);
end

function clear_package_functions(package_root)
folders = {fullfile(package_root,'bvartools'), ...
    fullfile(package_root,'cmintools')};
for d = 1:numel(folders)
    if ~isfolder(folders{d}), continue; end
    files = dir(fullfile(folders{d},'*.m'));
    for i = 1:numel(files)
        [~,name] = fileparts(files(i).name);
        clear(name);
    end
end
clear('fastbvar_');
end
