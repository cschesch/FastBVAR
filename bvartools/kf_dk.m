function   [shatnew,signew,lh,yhat,fin,kgpart,yforc]=kf_dk(y,H,shat,sig,G,M,companion_n,spred)

% =========================================================================
% KF_DK  
% function [shatnew,signew,lh,yhat,fin,kgain,yforc]=kf_dk(y,H,shat,sig,G,M)
% 
% This is Chris Sims's KF with a couple of added outputs 
% 1) The (Partial) Kalman Gain and F^(-1) matrices obtained using the 
%     Generalized Inverse are part of the output
% s(t) = G*s(t-1) + R*n(t)  V( n(t) ) = Q 
% then   M=R*Chol(Q)'=R( CQ') 
%        M*M'=R*( CQ'*CQ )*R'
% 
% See KF_MOD. for a related filter 
% NOTE: KGPART is NOT the appropriate Kalman Gain 
% KG=G*KGPART such that 
% KGPART=(P(t)|t-1)*(H')*(F^-1) 
% Use this version when the G matix is time varying and adjust to the 
% timing in DK which have a different timing in the state equation 
% =======================================================================
% Revised, 2/15/2017
% Revised, 3/21/2018

lh=zeros(1,2);
if nargin >= 7 && ~isempty(companion_n)
    % Exact block propagation for a pure VAR companion matrix:
    % G=[A; I 0], M=[M1; 0]. This avoids a dense ns-by-ns product and
    % reduces propagation from O(ns^3) to O(N*ns^2).
    ns = size(G,1);
    nshift = ns-companion_n;
    AP = G(1:companion_n,:)*sig;
    omega = zeros(ns,ns);
    omega(1:companion_n,1:companion_n) = ...
        AP*G(1:companion_n,:)' + ...
        M(1:companion_n,:)*M(1:companion_n,:)';
    if nshift > 0
        omega(1:companion_n,companion_n+1:end) = AP(:,1:nshift);
        omega(companion_n+1:end,1:companion_n) = AP(:,1:nshift)';
        omega(companion_n+1:end,companion_n+1:end) = ...
            sig(1:nshift,1:nshift);
    end
else
    omega=G*sig*G'+M*M';
end
if nargin < 8 || isempty(spred)
    if nargin >= 7 && ~isempty(companion_n)
        spred = [G(1:companion_n,:)*shat; ...
                 shat(1:end-companion_n)];
    else
        spred = G*shat;
    end
end
yforc = H*spred; 
yhat=y-yforc; 

% Fast full-rank path. The innovation covariance is at most the number of
% observed variables, whereas OMEGA has the full N*p companion dimension.
% Algebraically this is the same update as the square-root SVD formulation
% below. Retain that formulation as a robust fallback near rank deficiency.
F = H*omega*H';
F = (F+F')/2;
[R,chol_status] = chol(F);
if chol_status == 0 && rcond(R) > 1e-10
    omegaHt = omega*H';
    innovation_factor = omegaHt/R;
    kgain = innovation_factor/R';
    fin = R \ (R' \ eye(size(F)));
    ferr = R' \ yhat;
    lh(1) = -.5*((ferr')*ferr);
    lh(2) = -sum(log(diag(R)));
    shatnew = spred + kgain*yhat;
    signew = omega - innovation_factor*innovation_factor';
    signew = (signew+signew')/2;
    kgpart = kgain;
else
    [uo,doo,vo]=svd(omega);
    [u,d,v]=svd(H*uo*sqrt(doo));
    first0=min(find(diag(d)<1e-12));
    if isempty(first0),first0=min(size(H))+1;end
    u=u(:,1:first0-1);
    v=v(:,1:first0-1);
    d=diag(d);d=diag(d(1:first0-1));
    fac=vo*sqrt(doo);
    fhalf=(v/d)*u';
    fin=fhalf'*fhalf;
    ferr=fhalf*yhat;
    lh(1)=-.5*ferr'*ferr;
    lh(2)=-sum(log(diag(d)));
    kgpart=fac*fhalf;
    shatnew=fac*ferr+spred;
    signew=fac*(eye(size(v,1))-v*v')*fac';
end
lh=sum(lh);
