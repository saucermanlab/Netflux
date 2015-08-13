function writeXLSX(specList, rxnList, xlsname)
% Writes a Netflux .xlsx model with default parameters
%
%   WRITEXLSX(specList, rxnList, xlsname) takes a list of species and
%   reactions and writes them to an excel file with with name xlsname.
%   Default parameters are supplied (w=1, n=1.4, ec50 = 0.5, tau = 1, ymax
%   = 1, yinit = 0) . The variable xlsname can be an absolute or relative
%   path.
%
%   EXAMPLES:
%   
%   writeXLSX(specList, rxnList, 'C:\Documents\xlsname.xlsx');
%   writeXLSX(specList, rxnList, 'xlsname.xlsx');


% write the species list
spec2write = {};
for i = 1:length(specList)
    spec2write{end+1, 1} = '';
    spec2write{end, 2} = specList{i}; % write specID
    spec2write{end, 3} = specList{i}; % make default species name the same as specID
    spec2write{end, 4} = 0; % yinit = 0
    spec2write{end, 5} = 1; % ymax = 1
    spec2write{end, 6} = 1; % tau = 1
    spec2write{end, 7} = ''; % default "Type" is empty string
    spec2write{end, 8} = ''; % default "location" is empty string
    spec2write{end, 9} = ''; % default ref is empty string
    spec2write{end, 10} = ''; % default notes is empty string
end

header1 = {'Species', '','','','','','','','',''};
headers = {'Module', 'ID', 'name', 'Yinit', 'Ymax', 'tau', 'type', 'location', 'ref', 'notes'};
spec2write = vertcat(header1,headers, spec2write);

% create formatted cell array to be written to excel file
toWrite = {};
createdRxnList = {};
for i = 1:length(rxnList)
    rxnID = ['r', num2str(i)];
    createdRxnList{end+1} = rxnID;
    toWrite{end+1, 1} = ''; % Empty space for 'Module' column in sheet
    toWrite{end, 2} = rxnID; % write the reaction ID
    toWrite{end, 3} = rxnList{i}; % write the reaction rule
    toWrite{end,4} = 1; % set default weight of intermediate reactions to 1
    toWrite{end, 5} = 1.4; % set default n to 1.4
    toWrite{end, 6} = 0.5; % set default EC50 to 0.5
    toWrite{end, 7} = ''; % location
    toWrite{end, 8} = ''; % confidence 1
    toWrite{end, 9} = ''; % species 1
    toWrite{end, 10} = ''; % system 1
    toWrite{end, 11} = ''; % database 1
    toWrite{end, 12} = ''; % refID 1
    toWrite{end, 13} = ''; % link 1
    toWrite{end, 14} = ''; % confidence 2
    toWrite{end, 15} = ''; % species 2
    toWrite{end, 16} = ''; % system 2
    toWrite{end, 17} = ''; % database 2
    toWrite{end, 18} = ''; % refID 2
    toWrite{end, 19} = ''; % link 2
end

% write appropriate headers
header1 = {'Reactions', '','','','','','','','','','','','','','','','','',''};
headers = {'module', 'ID', 'Rule', 'Weight', 'n', 'EC50',...
    'location', 'confidence 1', 'species 1', 'system 1','database 1', 'refID 1', 'link 1',...
    'confidence 2', 'species 2', 'system 2','database 2', 'refID 2', 'link 2'};

% concatenate and write
toWrite = vertcat(header1, headers, toWrite);

xlwrite(xlsname, spec2write,'species');
xlwrite(xlsname, toWrite, 'reactions');
