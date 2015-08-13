function [dir] = sbml2sif(xmlfname, outputfname)
% imports an sbmlqual file and generates a .sif, nodeAttributes, and
% Netflux xls model file in current directory
if nargin == 1
    namepos = findstr('.xml', xmlfname);
    namestr = xmlfname(1:namepos-1);
    namestr = cellstr(namestr);
else
    namestr = outputfname;
end

% read the sbml file
import = xml2struct(xmlfname);

% Extract the species names
specStruct = import.sbml.model.qual_colon_listOfQualitativeSpecies.qual_colon_qualitativeSpecies;

% loop through all species in structure array
for i = 1:length(specStruct)
    specID{i} = specStruct{i}.Attributes.qual_colon_name;
end
specID = specID';

% extract the reactions from imported struct
rxnStruct = import.sbml.model.qual_colon_listOfTransitions.qual_colon_transition;
for i = 1:length(rxnStruct)
    inputs{i} = rxnStruct{i}.qual_colon_listOfInputs.qual_colon_input.Attributes.qual_colon_qualitativeSpecies;
    type{i} = rxnStruct{i}.qual_colon_listOfInputs.qual_colon_input.Attributes.qual_colon_sign;
    outputs{i} = rxnStruct{i}.qual_colon_listOfOutputs.qual_colon_output.Attributes.qual_colon_qualitativeSpecies;
end

% remove qual_ from species names
for i = 1:length(inputs)
    inputs{i} = strrep(inputs{i}, 'qual_', '');
    outputs{i} = strrep(outputs{i}, 'qual_', '');
end
specList = unique(vertcat(inputs, outputs));

% modelInputs = setdiff(inputs,outputs); % Inputs don't have any other inputs to their node, setdiff finds them
% 
% for i = 1:length(inputs)
%     if strcmp(type{i},'negative')
%         inputs{i} = strrep(inputs{i}, inputs{i}, ['!', inputs{i}]);
%     end
% end

% need to write them to sif file in a way that importsif can build the
% proper xls file from. 

% convert it to intermat and notMat, then send it to cna2cytoscape
% just write it to reaction strings and write to excel to get to cytoscape

% I am going to write the excel file

% write the species list
spec2write = {};
for i = 1:length(specList)
    spec2write{end+1, 1} = '';
    spec2write{end, 2} = specList{i}; % write specID
    spec2write{end, 3} = specList{i}; % make default species name the same as specID
    spec2write{end, 4} = num2str(0); % yinit = 0
    spec2write{end, 5} = num2str(1); % ymax = 1
    spec2write{end, 6} = num2str(1); % tau = 1
end

header1 = {'Species', '','','','',''};
headers = {'Module', 'ID', 'name', 'Yinit', 'Ymax', 'tau'};
spec2write = vertcat(header1,headers, spec2write);

% write the reactions sheet
rxnStr = {};
% for i = 1:length(modelInputs);
%     rxnStr{end+1} = sprintf('\''=> %s', char(modelInputs{i})); % (=> str) not acceptable in excel, make it ('=> str) instead
% end
for i = 1:length(inputs)
    if ~strcmp(inputs{i},outputs{i})
        rxnStr{end+1} = sprintf('%s => %s', inputs{i}, outputs{i}); % construct the reaction string with => between reactants and products
    end
end
rxn2write = rxnStr;

% create formatted cell array to be written to excel file
toWrite = {};
createdRxnList = {};
for i = 1:length(rxn2write)
    rxnID = ['r', num2str(i)];
    createdRxnList{end+1} = rxnID;
    toWrite{end+1, 1} = ''; % Empty space for 'Module' column in sheet
    toWrite{end, 2} = rxnID; % write the reaction ID
    toWrite{end, 3} = rxn2write{i}; % write the reaction rule
%     if i <= length(modelInputs)
%         toWrite{end, 4} = num2str(0); % set default weight of input reactions to zero
%     else
        toWrite{end,4} = num2str(1); % set default weight of intermediate reactions to 1
%     end
    toWrite{end, 5} = num2str(1.4); % set default n to 1.4
    toWrite{end, 6} = num2str(0.5); % set default EC50 to 0.5
end

% write appropriate headers
header1 = {'Reactions', '','','','',''};
headers = {'module', 'ID', 'Rule', 'Weight', 'n', 'EC50'};
toWrite = vertcat(header1, headers, toWrite);

exportName = strjoin([cellstr(namestr), 'Netflux.xlsx']);
pathstr = char(fullfile(cd, char(namestr)));
mkdir(char(pathstr));
dir = pathstr;
addpath(char(pathstr));
xlsname = char(fullfile(pathstr, sprintf('%s Netflux.xlsx', char(namestr))));
xlswrite(xlsname, spec2write,'species');
xlswrite(xlsname, toWrite, 'reactions');

cd(char(pathstr));
% create the .sif file from the exported excel file
[~,~,~,~,~,CNAmodel] = util.xls2Netflux(strrep(exportName, '.xlsx', ''), exportName);
util.cna2cytoscape(CNAmodel, pathstr)
cd(char('C:\Users\amp2hj\Documents\MATLAB\Batch Model Convert'));



