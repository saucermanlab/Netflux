function dydt = ODE(t,y,params,ODElist)
% Passed to the differential equation solver to solve the ODEs
%
% This file is passed to the differential solver, where the parameters are
% given by the input "params" and the differential equations are located in
% "ODElist"
% Input: params = matrix of parameters
%        ODElist = a cell array containing the differential equations
% Written by Stephen Dang on 2-5-10

% Assign names for parameters
[rpar,tau,ymax,speciesNames]=params{:};

%Differential Equations
for i = 1:length(ODElist) 
    eval(ODElist{i});
end

%% utility functions
function fact = act(x,rpar)
% hill activation function with parameters w (weight), n (Hill coeff), K';
    w = rpar(1);
    n = rpar(2);
    EC50 = rpar(3);
    beta = (EC50.^n - 1)./(2*EC50.^n - 1);
    K = (beta - 1).^(1./n);
    fact = w.*(beta.*x.^n)./(K.^n + x.^n);
    if fact>w,                 % cap fact(x)<= 1';
        fact = w;
    end

function finhib = inhib(x,rpar)
% inverse hill function with parameters w (weight), n (Hill coeff), K (K0.5)';
    finhib = rpar(1) - act(x,rpar);

function z = OR(x,y)
% OR logic gate
    z = x + y - x*y;
    
function z = AND(rpar,varargin)
% AND logic gate, multiplying all of the reactants together
    w = rpar(1);
    if w == 0,
        z = 0;
    else
        v = cell2mat(varargin);
        z = prod(v)/w^(nargin-2); % need to divide by w^(#reactants-1) to eliminate the extra w's
    end