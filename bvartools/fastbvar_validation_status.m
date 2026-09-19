function status = fastbvar_validation_status(options,varargin)
%FASTBVAR_VALIDATION_STATUS Query or session-register an option signature.

persistent session_signatures
if isempty(session_signatures), session_signatures = {}; end
if ischar(options) && strcmp(options,'register')
    signature = varargin{1};
    session_signatures = unique([session_signatures,{signature}]);
    status = [];
    return;
end
registry = fastbvar_validation_registry();
signature = fastbvar_option_signature(options);
has_uncertifiable_callback = any(ismember(fieldnames(options), ...
    registry.always_unvalidated));
status = struct('signature',signature, ...
    'validated',~has_uncertifiable_callback && ...
        ismember(signature,[registry.validated_signatures,session_signatures]), ...
    'known_fields',{registry.known_fields});
end
