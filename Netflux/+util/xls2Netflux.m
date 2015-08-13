function [specID,reactionIDs,reactionRules,paramList,ODElist,CNAmodel, ReadError]=xls2Netflux(networkID,xlsfilename)
% Reads the Netflux Excel spreadsheet and converts them to differential equations
%
% Converts an Excel spreadsheet of specified format into a Normalized-Hill differential
% equation system version version 0.08a, last modified 08/30/2011 by JJS
% 
% Notes:
%   1) xls2Netflux makes a number of assumptions about the xlsfile
%   structure
%       and will throw errors if there are problem: 'species' sheet: ID's
%       in column B, starting in row 3, names in column C 'reactions'
%       sheet: ID's in column B starting in row 3, reaction rule in column C
% Dependencies: cna2Netflux load XLS network reconstruction and read
% species, reaction rules

global statusLabel
if ~exist('xlsfilename','var')
    [fname,pathname,filterindex]=uigetfile('*.xls;*.xlsx','Open XLS network reconstruction');
    xlsfilename = [pathname fname];
end
pathname = strrep(xlsfilename,[networkID '.xls'],''); 
warning off MATLAB:xlsread:Mode;

[~,speciesSheetTxt,raw]=xlsread(xlsfilename,'species','','basic'); %reason for speciesSheetNum and reactionSheetNum? - In order to get to the Txt, need to get to the Num first

specID = strtrim(speciesSheetTxt(3:end,2)); % Species ID in column B; 3:end specifies rows, 2 specifies column
specNames = speciesSheetTxt(3:end,3); % Species Name in column C

% delete species with no specID
noValue = cellfun(@isempty,specID);
specID(noValue) = [];
specNames(noValue) = [];

numSpecs = length(specID);

% This error is caused by an error in XLSread in basic mode. 
if numSpecs == 0
    error('SpeciesError:NoSpecies','Number of species is zero, check spreadsheet or try saving as .xlsx');
end

varError = {};
eIndex = {};
try
    specErrs = {};
    for i = 1:length(specID)
        if ~isvarname(char(specID(i)))
            eIndex{end+1} = i;
        end
    end
    if ~isempty(eIndex)
        error('SpeciesError:Syntax', 'Species names must begin with letter and contain only letters, numbers, and underscores')
    end
catch
    eIndex = cell2mat(eIndex);
    for i = 1:length(eIndex)
        varError{end+1} = sprintf(specID{eIndex(i)});
    end
end

[~,reactionsSheetTxt,reactionsSheetRaw]=xlsread(xlsfilename,'reactions','','basic');
reactionIDs = reactionsSheetTxt(3:end,2); %Start Row 3, Column B
reactionRules = reactionsSheetTxt(3:end,3); %Start Row 3, Column C

% remove reaction and ID from respective lists if reaction rules aren't 
% present, if rules present but no ID, nothing is changed.
noRules = cellfun(@isempty, reactionRules);
reactionRules(noRules) = [];
reactionIDs(noRules) = [];

numRcns = length(reactionIDs);
interMat = zeros(numSpecs,numRcns);
notMat = zeros(numSpecs,numRcns);

% error is empty string if no error
XLSerror = [''];

% create cell arrays to hold error messages so they can all be
% concatenated and sent to the GUI after every reaction has been read. 
mismatchErrs = {};
NoProductsErrs = {};
NoReactantsErrs = {};
ArrowErrs = {};
DuplicateErrs = {};

% Determine if there are duplicate reactions in the .xls file.
try
    if length(unique(reactionRules)) < length(reactionRules)
        error('DuplicateError:DuplicateReaction', 'Duplicate reaction in reactions sheet');
    end
catch
    % find the indices of the repeats using the returned values from repval
    [duplicates, numRepeat, ind] = util.repval(reactionRules);
    [duplicates, numRepeat, ind] = util.repval(reactionRules);
    for i = 1:length(duplicates)
        for j = 1:numRepeat(i)
            if i == 1
                ids{i,j} = ind(j);
            else
                ids{i,j} = ind(sum(numRepeat(1:i-1)) + j);
            end
        end
    end
    % create error string from reaction rules and repval duplicates
    DuplicateErrs = {};
    for i = 1:length(duplicates)
        idstr = '';
        j = 1;
        while j <= length(ids(i,:)) && ~isempty(cell2mat(ids(i,j)))
            if j > 1
                idstr = sprintf(horzcat(idstr, '/',char(reactionIDs(ids{i,j}))));
            else
                idstr = sprintf(horzcat(idstr, char(reactionIDs(ids{i,j}))));
            end
            j = j+1;
        end
        DuplicateErrs{end+1} = sprintf([idstr, ': ', duplicates{i}]);
    end
end

for i=1:numRcns
    try
    % calculate interMat column for reaction 'i'
    specIDReg = cellfun(@(x) ['\<',x,'\>'],specID,'UniformOutput',false); % match must be the entire word
    rxnSpecies = regexp(reactionRules{i},specIDReg); 
    
%     if isempty(cell2mat(rxnSpecies))
%         error('RxnSyntax:NoSpeciesMatch', 'No species recognized in reaction');
%     end
%     
    eqPos = findstr('=>',reactionRules{i});
    
    % display error if no equal position detected
    if isempty(eqPos)
        error('RxnSyntax:NoReactionArrow', 'No reaction arrow was detected, check syntax');
    end
    
    % parse out the reactants and products from the string
    reactants = zeros(size(rxnSpecies));
    products = zeros(size(rxnSpecies));
    for j = 1:length(rxnSpecies)
        array = rxnSpecies{j};
        for k = 1:length(array)
            if array(k) < eqPos
                reactants(j,1) = -1;
            elseif array(k) > eqPos
                products(j,1) = 1;
            end
        end
    end
        
    interMat(:,i) = reactants+products;   
    rMat(:,i) = reactants; % reactantMat
    pMat(:,i) = products; % productMat
    % error if no products are written in reaction
    if ~ismember(1,products)
        error('RxnSyntax:NoProducts', 'No products in reaction');
    end
    
    % If there are no reactants in interMat, but there are letters before
    % =>, then error. 
    reactantStr = reactionRules{i};
    if ~ismember(-1,reactants) && ~isempty(reactantStr(1:eqPos-1))
        error('RxnSyntax:ReactantsNotRecognized', 'Reactants not recognized, may be misspelled')
    end
    
    % Detect # of attempted reactants from number of '&'s, then compare to actual # of
    % reactants placed in matrix, if they don't match, then error
    if length(find(reactantStr(1:eqPos-1)=='&')) + 1 > length(find(reactants == -1)) ...
            && ~isempty(reactantStr(1:eqPos-1))
        error('RxnSyntax:ReactantsNotRecognized', 'One or more reactants not recognized, make sure all species appear exactly as they are in the species sheet');
    end
    
    % calculate notMat column for reaction 'i'
    notSpecID = cellfun(@(x) ['!',x],specID,'UniformOutput',false);
    rxnNotSpecies = regexp(reactionRules{i},notSpecID);
    notMat(:,i) = cellfun('isempty',rxnNotSpecies);
    
    catch err
        if strcmp(err.identifier, 'RxnSyntax:NoSpeciesMatch')
            mismatchErrs{end+1} = sprintf([reactionIDs{i},':', reactionRules{i}]);
            
        elseif strcmp(err.identifier, 'RxnSyntax:NoProducts')
            NoProductsErrs{end+1} = sprintf([reactionIDs{i},':',reactionRules{i}]);
            
        elseif strcmp(err.identifier, 'RxnSyntax:ReactantsNotRecognized')
            NoReactantsErrs{end+1} = sprintf([ reactionIDs{i},':',reactionRules{i}]);
            
        elseif strcmp(err.identifier, 'RxnSyntax:NoReactionArrow')
            ArrowErrs{end+1} = sprintf([ reactionIDs{i},':',reactionRules{i}]);
        else
            rethrow(err)
        end
    end
    
    % organize errors into a cell array based on error type for return to
    % the gui, if there are no errors of a certain type, it is not added to
    % the XLSerror cell array.
    XLSerror = {};
    if ~isempty(varError)
        XLSerror{end+1} = 'Warning: Invalid species name(s):';
        for m = 1:length(varError)
            XLSerror{end+1} = varError{m};
        end
        XLSerror{end+1} = '';
    end
    if ~isempty(mismatchErrs)
        XLSerror{end+1} = 'Warning: No species recognized:';
        for m = 1:length(mismatchErrs)
            XLSerror{end+1} = mismatchErrs{m};
        end
        XLSerror{end+1} = '';
    end
    if ~isempty(NoProductsErrs)
        XLSerror{end+1} = 'Warning: Product not recognized';
        for m = 1:length(NoProductsErrs)
            XLSerror{end+1} = NoProductsErrs{m};
        end
        XLSerror{end+1} = '';
    end
    if ~isempty(NoReactantsErrs)
        XLSerror{end+1} = 'Warning: Reactant(s) not recognized';
        for m = 1:length(NoReactantsErrs)
            XLSerror{end+1} = NoReactantsErrs{m};
        end
        XLSerror{end+1} = '';
    end
    if ~isempty(ArrowErrs)
        XLSerror{end+1} = 'Warning: No reaction arrow could be identified';
        for m = 1:length(ArrowErrs)
            XLSerror{end+1} = ArrowErrs{m};
        end
        XLSerror{end+1} = '';
    end
    if ~isempty(DuplicateErrs)
        XLSerror{end+1} = 'Warning: Duplicate reactions detected';
        for m = 1:length(DuplicateErrs);
            XLSerror{end+1} = DuplicateErrs{m};
        end
        XLSerror{end+1} = '';
    end     
    if isempty(XLSerror)
        XLSerror = [''];
    end
end

% create model structure CNAmodel and then create ODE files via cna2Netflux
CNAmodel.specID = char(specID); % store specID in a character array
CNAmodel.interMat = interMat;
CNAmodel.reactantMat = rMat;
CNAmodel.productMat = pMat;
CNAmodel.notMat = notMat;
CNAmodel.net_var_name = networkID;
CNAmodel.type = speciesSheetTxt(3:end, 7);
CNAmodel.location = speciesSheetTxt(3:end,8);
CNAmodel.module = speciesSheetTxt(3:end, 1);
CNAmodel.ref = speciesSheetTxt(3:end, 9);

for i=1:size(CNAmodel.specID,1)
    speciesNames{i} = strtrim(CNAmodel.specID(i,:));
end
[paramList,ODElist, CNAerror] = util.Netflux2ODE(CNAmodel,xlsfilename);

% 2 possible errors one from xls2Netflux and the other from
% CNA2Netflux, assign each to a cell for return to GUI. 
if ~isequal('', XLSerror) && ~isequal('',CNAerror)
    ReadError = {XLSerror{:}, CNAerror{:}};
elseif ~isequal('', XLSerror)
    ReadError = {XLSerror{:}};
elseif ~isequal('', CNAerror)
    ReadError = {CNAerror{:}};
else 
    ReadError = {'',''}; % only happens when there are no errors
end
