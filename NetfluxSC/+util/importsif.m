function importsif(sifFile, outputFileName)
% Converts a sif file to a Netflux Excel file
%   
%   IMPORTSIF(sifFile, outputFileName) writes a Netflux .xlsx file to the
%   location specified by outputFileName. outputFileName can be an absolute
%   or relative path.
%   
%   NOTE: The program makes a number of assumptions about the structure of
%   the SIF file: 
%       1) Each line must be tab delimited with format 
%       'reactant     #      product'
%       where #=1 corresponds to an activating relationship and #=-1
%       corresponds to an inhibiting relationship.
%
%           EXAMPLE: 
%                AC	1	cAMP
%                CaMK	-1	HDAC
%
%             will be translated to: 
%                AC => cAMP
%                !CaMK => HDAC
%
%       2) AND relationships must be written in the SIF file with the
%       following the format:
%              'connector     #      output'
%              'input1        #      connector'
%              'input2        #      connector'
%              ...
%              'inputN        #      connector'
%          where connector is an alphanumeric string with the format 'rcn#'
%
%       EXAMPLE: 
%               rcn22	1	SERCA
%               cFos	-1	rcn22
%               cJun	-1	rcn22
%               NFAT	-1	rcn22
%
%          will be translated to: 
%              !cFos & !cJun & !NFAT => SERCA

sif = textread(sifFile, '%s', 'delimiter', '\n');
sif2 = {};
for i = 1:length(sif); % convert to cell array of strings
    split = strsplit(sif{i},'\t');
    sif2 = vertcat(sif2, split);
end 
sif2 = cellstr(sif2);
sif = sif2;

temp = regexp(sif(:,1), 'rcn'); % find where and relationships start
temp2 = cellfun(@(x)~isempty(x),temp); % convert to array of logicals
andIndex = find(temp2 == 1); % find the line number indices of the and relationships

i = 1; %tracks line number
rxnStrings = {};

specs = vertcat(sif(:,1), sif(:,3));
temp = regexp(specs, 'rcn');
connectorNodeIndex = cellfun(@(x)~isempty(x), temp);
specs(connectorNodeIndex) = [];
specs = unique(specs);
specID = specs;
atEndSif = false;

% read the formatted cell array
while ~atEndSif
    if any(i == andIndex) %if you are at the start of an AND relationship
        
        output = sif(i,3);
        atEndRcn = false;
        connectorNodeStr = sif(i, 1);
        inputs = {};
        rxnType = {};
        
        while ~atEndRcn
            i = i+1;
            inputs(end+1) = sif(i, 1);
            inhibitor = isequal(cell2mat(sif(i,2)),'-1');
            
            if inhibitor %append ! to species
                inputs{end} = sprintf('!%s', inputs{end});
            end
            
            atEndRcn = ~strcmp(sif(i+1, 3), connectorNodeStr); %if at end reaction strings don't match
            
            if ~atEndRcn
                inputs(end+1) = cellstr('&');
            end
        end
        
        rxnStrings{end+1} = sprintf('%s => %s', strjoin(inputs), char(output));
        
        i = i+1;
        
    else
        input = sif(i,1);
        output = sif(i,3);
        rxnType = sif(i,2);
        
        inhibitor = isequal(cell2mat(sif(i,2)),'-1');
        
        if inhibitor %append ! to species
            input = sprintf('!%s', char(input));
        end
        
        i = i+1;
        rxnStrings{end+1} = sprintf('%s => %s', char(input), char(output));
        
    end
    
    if i>size(sif,1)
        atEndSif = true;
    end
end

util.writeXLSX(specID, rxnStrings, outputFileName)

        
