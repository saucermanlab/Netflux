function outputfname = sbml2sif(sbmlfname,dirname)
% Converts an SBML-QUAL file to a Netflux Excel file. 
%   
%   outputfname = SBML2SIF(sbmlfname) imports an SBML-QUAL file and
%   generates a folder containing the corresponding .sif, nodeAttributes,
%   and Netflux .xlsx model files in the current directory. The program
%   returns the folder location to outputfname.
%
%   outputfname = SBML2SIF(sbmlfname,dirname) outputs the converted files
%   to the specified directory given by dirname.
%
%   EXAMPLES:   
%   
%   SBML2SIF('MAPK.xml', cd);


if exist(dirname) == 0 || nargin < 2
    [~, default] = fileparts(sbmlfname);
    dirname = fullfile(cd,default);
    mkdir(dirname);
end

[~,namestr] = fileparts(sbmlfname);
namestr = cellstr(namestr);

% read the sbml file
import = util.xml2struct(sbmlfname);

% Extract the species names
specStruct = import.sbml.model.qual_colon_listOfQualitativeSpecies.qual_colon_qualitativeSpecies;

% loop through all species in structure array
for i = 1:length(specStruct)
    specID{i} = specStruct{i}.Attributes.qual_colon_name;
end
specID = specID';

% extract the reactions from imported struct
rxnStruct = import.sbml.model.qual_colon_listOfTransitions.qual_colon_transition;
if length(rxnStruct) > 1
    for i = 1:length(rxnStruct)
        inputs{i} = rxnStruct{i}.qual_colon_listOfInputs.qual_colon_input.Attributes.qual_colon_qualitativeSpecies;
        try
            type{i} = rxnStruct{i}.qual_colon_listOfInputs.qual_colon_input.Attributes.qual_colon_sign;
        catch e % if type not specified, provide positive as default
            type{i} = 'positive';
        end
        outputs{i} = rxnStruct{i}.qual_colon_listOfOutputs.qual_colon_output.Attributes.qual_colon_qualitativeSpecies;
    end
else % if only one reaction in SBML-QUAL
    inputs = rxnStruct.qual_colon_listOfInputs.qual_colon_input.Attributes.qual_colon_qualitativeSpecies;
    try
        type{i} = rxnStruct.qual_colon_listOfInputs.qual_colon_input.Attributes.qual_colon_sign;
    catch e % if type not specified, provide positive as default
        type{i} = 'positive';
    end
    outputs = rxnStruct.qual_colon_listOfOutputs.qual_colon_output.Attributes.qual_colon_qualitativeSpecies;
end

% remove qual_ from species names
if ~ischar(inputs) % will be char if only one input
    for i = 1:length(inputs)
        inputs{i} = strrep(inputs{i}, 'qual_', '');
        outputs{i} = strrep(outputs{i}, 'qual_', '');
    end
else
    inputs = strrep(inputs,'qual_','');
    outputs = strrep(outputs,'qual_','');
    inputs = cellstr(inputs);
    outputs = cellstr(outputs);
end
specList = unique(vertcat(inputs, outputs));

rxnList = {};
for i = 1:length(inputs)
    if strcmp(type{i},'negative')
        inputs{i} = strrep(inputs{i}, inputs{i}, ['!', inputs{i}]);
    end
    rxnList{end+1} = sprintf('%s => %s', inputs{i}, outputs{i});
end

% need to write them to sif file in a way that importsif can build the
% proper xls file from. 

oldcd = cd;
cd(dirname);
addpath(dirname);
outputfname = dirname;
exportName = strjoin([namestr, 'Netflux.xls']);
xlsname = char(fullfile(dirname, exportName));

util.writeXLSX(specList, rxnList, xlsname)

% create the .sif file from the exported excel file
[~,~,~,~,~,CNAmodel] = util.xls2Netflux(strrep(exportName, '.xls', ''), exportName);
util.Netflux2sif(CNAmodel, dirname)

cd(oldcd);

