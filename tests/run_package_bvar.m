function output = run_package_bvar(package_root, y, lags, options, use_alias)
%RUN_PACKAGE_BVAR Invoke one checkout without allowing MATLAB path leakage.

if nargin < 5
    use_alias = false;
end

old_path = path;
cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
clear_package_functions(package_root);
addpath(fullfile(package_root, 'cmintools'), '-begin');
addpath(fullfile(package_root, 'bvartools'), '-begin');
if use_alias
    addpath(package_root, '-begin');
    output = fastbvar_(y, lags, options);
else
    output = bvar_(y, lags, options);
end
clear_package_functions(package_root);
end

function clear_package_functions(package_root)
folders = {fullfile(package_root, 'bvartools'), ...
           fullfile(package_root, 'cmintools')};
for d = 1:numel(folders)
    listing = dir(fullfile(folders{d}, '*.m'));
    for i = 1:numel(listing)
        [~, name] = fileparts(listing(i).name);
        clear(name);
    end
end
clear('fastbvar_');
end

