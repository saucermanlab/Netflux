function Netflux2sif(cnamodel,pname)
%Converts Netflux model structure to Cytoscape .sif and node attributes file
%
% Version 0.08a 08/31/2011 by JJS
% Outputs (written to the current directory):
% 1) SIF interaction file named 'cnap.path'.sif. Contains the interactions.
% 2) Node attributes file named 'cnap.path'_nodeAttributes.txt. 
%    Tells cytoscape what type of node each species is for SBGN property
%    file (e.g. small molecule, connector, protein, mRNA, phenotype)
% 
% Notes:
%   1) Rcns with no reactants (input fluxes) are skipped.
%   2) Rcns with no products (output fluxes) are skipped.
%   3) Tested with CellNetAnalyzer 9.2 and Cytoscape 2.6.

modelName = cnamodel.net_var_name;
specID = cellstr(cnamodel.specID);
interMat = cnamodel.interMat;
reactantMat = cnamodel.reactantMat;
productMat = cnamodel.productMat;
notMat = cnamodel.notMat;

numRcns = size(interMat,2);
rcnList={};
connectorList={};

% Write SIF file with reactions
fid = fopen(fullfile(pname, sprintf('%s.sif', modelName)),'wt');

for rcnNum = 1:numRcns
	reactants = find(reactantMat(:,rcnNum)==-1);
	numReactants = size(reactants,1);
	products = find(productMat(:,rcnNum)==1);   
    numProducts = size(products,1);
	if (numReactants==1) && (numProducts==1)    % skips rcns with no reactants or products                                  
		if notMat(reactants,rcnNum)==1
            % write tab delimited line with reactant, 1 (activating) or -1, and product
			fprintf(fid, '%s\t1\t%s\n', char(specID(reactants)), char(specID(products)));
        else
			fprintf(fid, '%s\t-1\t%s\n', char(specID(reactants)), char(specID(products)));
		end
	elseif (numReactants>1) && (numProducts==1)
		connectorNode = ['rcn',num2str(rcnNum)];
    	fprintf(fid, '%s\t1\t%s\n', connectorNode, char(specID(products))); % prints tab delimited str of type (reactant   1     product) 
        connectorList{end+1} = connectorNode;
		for j=1:numReactants
			if notMat(reactants(j),rcnNum)==1
                fprintf(fid, '%s\t1\t%s\n', char(specID(reactants(j))), connectorNode);
			else
				fprintf(fid, '%s\t-1\t%s\n', char(specID(reactants(j))), connectorNode);
			end
        end
    end
end
fclose(fid);
disp(['Wrote ',fullfile(pname,modelName),'.sif']);

% Generate and export node attribute list

nfname = [modelName,'_nodeAttributes.txt'];
nfname = fullfile(pname,nfname);
fid2 = fopen(nfname, 'wt');
fprintf(fid2, 'Type (class=String)\n'); % header
type = cnamodel.type;
for i = 1:length(specID)
    fprintf(fid2,'%s = %s\n', specID{i}, type{i}); % write each node
end
for i = 1:length(connectorList);
    fprintf(fid2,'%s = connector\n', connectorList{i}); % write each connector
end
fclose(fid2);

disp(['Wrote ',fullfile(pname,modelName),'_nodeAttributes.txt']);