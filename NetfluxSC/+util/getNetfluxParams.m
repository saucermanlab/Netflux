function [paramList, CNAerror] = getNetfluxParams(xlsfilename)
% Extracts the parameters from Netflux Excel file
%
%   GETNETFLUXPARAMS also checks the .xlsx file for syntax errors, some of
%   which are corrected by assigning default parameters. 
%
%   outputs:
%       1) paramList: cell array containing the parameters
%       2) CNAerror: cell array containing error messages, if any.
try
    [speciesSheetNum,speciesSheetTxt,raw]=xlsread(xlsfilename,'species','','basic');
    
    y0 = raw(3:end,4);
    ymax = raw(3:end,5);
    tau = raw(3:end,6);
    
    y0 = cell2mat(y0);
    ymax = cell2mat(ymax);
    tau = cell2mat(tau);
    ymaxTxt = speciesSheetTxt (3:end,4);
    
    [reactionsSheetNum,reactionsSheetTxt,rxnraw]=xlsread(xlsfilename,'reactions','','basic');
    w = rxnraw(3:end,4);
    n = rxnraw(3:end,5);
    EC50 = rxnraw(3:end,6);
    
    w = cell2mat(w);
    n = cell2mat(n);
    EC50 = cell2mat(EC50);
         
    reactionIDs = reactionsSheetTxt(3:end,2);
    reactionRules = reactionsSheetTxt(3:end,3);
    specID = strtrim(speciesSheetTxt(3:end,2));
    
    % make sure all reactions have parameters. mismatchParams returns the ID
    % and reaction rule strings which do not have corresponding reaction
    % parameters, and sets default parameters to those reactions.

    noparams = '';
    [noparams, w, n, EC50] = mismatchParams(reactionRules,reactionIDs, w, n, EC50);

    % make sure all species have defined parameters, and set default
    % parameters for those that don't. 
    noSpecParams = '';
    [noSpecParams, y0, ymax, tau] = mismatchSpecParams(specID, y0, ymax, tau);
    
    % delete parameters that have no corresponding reaction rules. 
    noValue = cellfun(@isempty, reactionRules);
    w(noValue) = [];
    n(noValue) = [];
    EC50(noValue) = [];
    
    % delete parameters that have no corresponding speciesID
    noValue = cellfun(@isempty, specID);
    y0(noValue) = [];
    ymax(noValue) = [];
    tau(noValue) = [];
    
    % delete cells with no values in them to remove gaps
    noValue = cellfun(@isnan, num2cell(w)); % reaction parameters
    w(noValue) = [];
    noValue = cellfun(@isnan, num2cell(n));
    n(noValue) = [];
    noValue = cellfun(@isnan, num2cell(EC50));
    EC50(noValue) = [];
    
    noValue = cellfun(@isnan, num2cell(y0)); % species parameters
    y0(noValue) = [];
    noValue = cellfun(@isnan, num2cell(ymax));
    ymax(noValue) = [];
    noValue = cellfun(@isnan, num2cell(tau));
    tau(noValue) = [];
    
    % 1) remove reaction and ID from respective lists if reaction rules aren't
    % present, if rules present but no ID, nothing is changed.
    % 2) make sure that all reactions have defined paramaters

    noRules = cellfun(@isempty, reactionRules);
    reactionRules(noRules) = [];
    reactionIDs(noRules) = [];
    specID = strtrim(speciesSheetTxt(3:end,2));
    
    % delete species with no specID
    noValue = cellfun(@isempty,specID);
    specID(noValue) = [];
    
    numspecies = length(specID);
   
    w = w';
    n = n';
    EC50 = EC50';    
    
    [duplicates, numRepeat, ind] = util.repval(specID);
    for i = 1:length(duplicates)
        for j = 1:numRepeat(i)
            if i == 1
                ids{i,j} = ind(j);
            else
                ids{i,j} = ind(sum(numRepeat(1:i-1)) + j);
            end
        end
    end
    DuplicateErrs = {};
    for i = 1:length(duplicates)
        idstr = '';
        j = 1;
        while j <= length(ids(i,:)) && ~isempty(cell2mat(ids(i,j)))
            if j > 1
                idstr = sprintf(char(specID(ids{i,j})));
            else
                idstr = sprintf(char(specID(ids{i,j})));
            end
            j = j+1;
        end
        DuplicateErrs{end+1} = sprintf(idstr);
    end
        
    if ~isempty(noSpecParams) || ~isempty(noparams)
        error('ParamErr:MissingParams','Reaction or species parameters may be missing');
    end
    
    if ~isempty(DuplicateErrs)
        error('DuplicateError:DuplicateSpecies', 'Duplicate species detected');
    end
        CNAerror = ['']; % if no error, then return empty string in error message
catch
    CNAerror = {};
    if ~isempty(noparams);
        CNAerror{end+1} = 'Missing parameter(s) for following reactions';
        CNAerror{end+1} = '(default parameters assigned):';
        for j = 1:length(noparams)
            CNAerror{end+1} = noparams{j};
        end
        CNAerror{end+1} = '';
    end
    if ~isempty(noSpecParams);
        CNAerror{end+1} = 'Missing parameter(s) for following species';
        CNAerror{end+1} = '(default parameters assigned)';
        for j = 1:length(noSpecParams);
            CNAerror{end+1} = noSpecParams{j};
        end
        CNAerror{end+1} = '';
    end
    if ~isempty(DuplicateErrs);
        CNAerror{end+1} = 'Warning: Duplicate species detected';
        for m = 1:length(DuplicateErrs)
            CNAerror{end+1} = DuplicateErrs{m};
        end
        CNAerror{end+1} = '';
    end
end
paramList = {w,n,EC50,tau,ymax,y0}; %parameter list for ODE.m

%% Parameter mismatch functions
function [noparams, w, n, EC50] = mismatchParams(reactionRules,reactionIDs, w, n, EC50)
    %Returns the reactionID and reaction rule strings that don't have
    %defined parameters, and changes parameters for those reactions to the
    %default values
noparams = {};
ID = {};
for i = 1:length(reactionRules)
    missing = isnan(n(i)) || isnan(w(i)) || isnan(EC50(i));
    if~ismember('',reactionRules(i)) && missing
        noparams(end+1) = reactionRules(i);
        ID(end+1) = reactionIDs(i);
        noparams(end) = strcat(ID(end),': ',noparams(end));
        % change the parameters to the default for this reaction
        w(i) = 1;
        n(i) = 1.4;
        EC50(i) = .5;
    end
end
%%
function [noSpecParams, y0, ymax, tau] = mismatchSpecParams(specID, y0, ymax, tau)
% Returns the species IDs that don't have defined parameters and sets the
% parameters to the default values for those species. 
noSpecParams = {};
for i = 1:length(specID)
    missing = isnan(y0(i)) || isnan(ymax(i)) || isnan(tau(i));
    if ~ismember('',specID(i)) && missing
        noSpecParams(end+1) = specID(i);
        % change the parameters to the default for this reaction
        y0(i) = 0;
        ymax(i) = 1;
        tau(i) = 1;
    end
end