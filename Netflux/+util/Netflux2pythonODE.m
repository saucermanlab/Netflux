function [pythonODElist,CNAerror] = Netflux2pythonODE(cnamodel)
% Generates the system of differential equations
%
%   NETFLUX2ODE takes the cnamodel structure generated by xls2Netflux and
%   generates the system of normalized Hill differential equations. Outputs
%   ODElist and paramList are send to ODE to solve. Version 0.08a
%   08/30/2011 by JJS
%   07/01/2024 updated by Kaitlyn Wintruba

%% pull in info from cnamodel

interMat = cnamodel.interMat;
reactantMat = cnamodel.reactantMat;
productMat = cnamodel.productMat;
notMat = cnamodel.notMat;
cnaspecies = cnamodel.specID;
modelname = cnamodel.net_var_name;

speciesNames = strtrim(mat2cell(cnaspecies,ones(size(cnaspecies,1),1),size(cnaspecies,2)));   % store species as a cell array
numspecies = size(interMat,1);
numrxns = size(interMat,2);

%% Create ODElist, a cell array of strings containing the ODEs
reactions = calcReactions(reactantMat,productMat,notMat,speciesNames);
mapVar = cell(numspecies,1);
for i = 1:numspecies
    mapVar{i} = sprintf('\t%s = %d',speciesNames{i},i-1); % downshifted for Python
end
pythonODElist = cell(numspecies+1,1);
pythonODElist{1} = sprintf('\tdydt = np.zeros(%i)',numspecies); %Create matrix of Strings with Differential Equations

%Create matrix of Strings with Differential Equations
for i=1:numspecies
    s = speciesNames{i};
    if (exist('ymaxTxt') && isnan(ymax(i)) ),   % ymax specified as text instead of #
        ymaxStr = ymaxTxt{i};
    else
        ymaxStr = ['ymax[' s ']'];
    end
    pythonODElist{i+1} = sprintf('\tdydt[%s] = (%s*%s - y[%s])/tau[%s]',s,reactions{i},ymaxStr,s,s);
end
pythonODElist{end+1} = sprintf('\treturn dydt');
pythonODElist = [mapVar; pythonODElist];

%% function calcReactions
function reactions = calcReactions(reactantMat, productMat,notMat,speciesNames)
numspecies = size(reactantMat,1);
numrxns = size(reactantMat,2);

% generate reaction strings for each reaction of the form: act(y(A),rpar(:,1))
for i = 1:numrxns
    reactants = find(reactantMat(:,i)==-1);
    reactNumStr = num2str(i-1); % downshifted for python
    if isempty(reactants),                  % input reaction, of the form: w[3]
        str = ['w[' reactNumStr ']'];
    elseif length(reactants)==1,            % single reactant, of the form: act(y[A],w[3],n[3],EC50[3])
        if notMat(reactants,i) == 0
            str = ['inhib(y[' speciesNames{reactants} '],rpar[:,',reactNumStr,'])'];
        else
            str = ['act(y[' speciesNames{reactants} '],rpar[:,',reactNumStr,'])'];
        end
    else,                                   % multiple reactants, of the form: AND(w[3],[act(y[A],w[3],n[3],EC50[3]),inhib(y[B],w[3],n[3],EC50[3])])
        str = ['AND(w[',reactNumStr,'],['];
        for j = 1:length(reactants)         % loop over each reactant
            if notMat(reactants(j),i) == 0
                str = [str 'inhib(y[' speciesNames{reactants(j)} '],rpar[:,',reactNumStr,'])'];
            else
                str = [str 'act(y[' speciesNames{reactants(j)} '],rpar[:,',reactNumStr,'])'];
            end
            if j<length(reactants), % more reactants to come
                str = [str ','];
            end
        end
        str = [str '])']; % cap with close parentheses
    end
    rxnString{i} = str;
end

% combine relevant reactions for each species, using nested ORs if needed
for i=1:numspecies
    rxnList = find(productMat(i,:)==1);  % find reactions that affect specie 'i'
    if isempty(rxnList)              % 0 reactions for that specie
        reactions{i} = '0';
    elseif length(rxnList)==1,         % 1 reaction for that specie
        reactions{i} = rxnString{rxnList};
    elseif length(rxnList)>1           % combine reactions with nested 'OR's
        str = '';
        for j = 1:length(rxnList)-1
            str = [str 'OR(' rxnString{rxnList(j)} ','];
        end
        str = [str rxnString{rxnList(end)} repmat(')',1,j)];
        reactions{i} = str;
    end
end
