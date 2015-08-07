function Netflux2xgmml(CNAmodel, outXGMML, refXGMML)
% Writes Netflux model structure to an XGMML file
%   
%   NETFLUX2XGMML(CNAmodel,outXGMML) exports the Netflux model stored in
%   CNA model to an XGMML file (specified by outXGMML) for visualization in
%   Cytoscape. Default node graphics correspond to a modified SBGN process
%   description format. outXGMML and refXGMML can be relative or absolute
%   paths.
%
%   NETFLUX2XGMML(CNAmodel,outXGMML, refXGMML) exports the Netflux model
%   (CNAmodel) to an XGMML with graphics and node positions that are
%   defined in reference XGMML. The reference XGMML must have been exported
%   from Cytoscape 2.8.3. Graphics properties are copied on the basis of a
%   string comparison between node and edge labels in CNA model and
%   refXGMML. NOTE: If a node/edge does not exist in refXGMML but exists in
%   CNAmodel, the node/edge will be written with default graphics and
%   coordinates. If a node exists in refXGMML but not CNAmodel, it will not
%   be written to the new XGMML file.
%   
%   SBGN graphics are generated from the "type" column of the Species sheet
%   in the Netflux Excel file. The supported categories are protein, mRNA,
%   smallMolecule, phenotype, connector, and intermediate.

interMat = CNAmodel.interMat;
reactantMat = CNAmodel.reactantMat;
productMat = CNAmodel.productMat;
notMat = CNAmodel.notMat;
specID = cellstr(CNAmodel.specID);
typeList = CNAmodel.type;

refExists = false; % if reference XGMML was not specified
if nargin == 3 % if refXGMML was provided
    refExists = true;
    
    import = util.xml2struct(refXGMML);
    % Read each node from reference
    nodes = import.graph.node;
    for i = 1:length(nodes);
        xmlspecs{i} = nodes{i}.Attributes.label;
        if iscell(nodes{i}.att) % util.xml2struct saves data differently depending on number of attributes, if statements ensure uniform save structure for access in loop
            nodeAttributes{i} = nodes{i}.att; % returns cell of cells of structs, each struct is a different attribute
        else
            nodes{i} = struct('att', nodes{i});
            nodeAttributes{i} = {nodes{i}.att};
        end
        if isfield(nodes{i},'graphics')
            specGraphics{i} = nodes{i}.graphics;
        else
            specGraphics{i} = nodes{i}.att.graphics; %stored differently if length 1.
        end
    end
    
    % Read each edge from reference
    edges = import.graph.edge;
    for i = 1:length(edges)
        xmledgeID{i} = edges{i}.Attributes.label;
        edgeAttributes{i} = edges{i}.att; % returns cell of structs
        edgeGraphics{i} = edges{i}.graphics;
    end
end


% Generate the edges and nodes from the excel file/ CNA model
numRcns = size(interMat,2);
rcnList={};
connectorList={};
for rcnNum = 1:numRcns
    reactants = find(reactantMat(:,rcnNum)==-1);
    numReactants = size(reactants,1);
    products = find(productMat(:,rcnNum)==1);
    numProducts = size(products,1);
    if (numReactants==1) && (numProducts==1)    % skips rcns with no reactants or products
        if notMat(reactants,rcnNum)==1
            rcnText= sprintf('%s\t(1)\t%s', char(specID(reactants)), char(specID(products)));
        else
            rcnText = sprintf('%s\t(-1)\t%s', char(specID(reactants)), char(specID(products)));
        end
        rcnList{end+1} = rcnText;
    elseif (numReactants>1) && (numProducts==1)
        connectorNode = ['rcn',num2str(rcnNum)];
        rcnText = sprintf('%s\t(1)\t%s', connectorNode, char(specID(products))); % prints tab delimited str of type (reactant   (1)     product) 
        connectorList{end+1} = connectorNode;
        rcnList{end+1} = rcnText;
        for j=1:numReactants
            if notMat(reactants(j),rcnNum)==1
                rcnText = sprintf('%s\t(1)\t%s', char(specID(reactants(j))), connectorNode);
            else
                rcnText = sprintf('%s\t(-1)\t%s', char(specID(reactants(j))), connectorNode);
            end
            rcnList{end+1} = rcnText;
        end
    end
end

% Generate the node list from the excel file/CNA model
nodeList = cellstr(specID);
nodeLabel = nodeList; % save labels in new vector so rcnx can be labeled as AND in cytoscape
nodeList = vertcat(nodeList,connectorList');

% add node type "connector" to the end of the type list
for i = 1:length(connectorList);
    nodeLabel{end+1} = 'AND';
    typeList{end+1} = 'connector';
end

% start writing the xgmml file for each node
fid = fopen(outXGMML, 'w');

% write the XGMML header
fprintf(fid, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
fprintf(fid, '<graph label="Cytoscape" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:cy="http://www.cytoscape.org" xmlns="http://www.cs.rpi.edu/XGMML"  directed="1">\n');
fprintf(fid, '<att name="documentVersion" value="1.1"/>\n');

% write each node to XGMML
id = []; % save the assigned xml node ids for edges later
for i = 1:length(nodeList)
    if refExists && ismember(nodeList{i}, xmlspecs) % if node defined in previous xgmml
        [~, index] = ismember(nodeList{i}, xmlspecs); % index = index of match
        id(end+1) = i;
        
        % write node header
        fprintf(fid, '<node label="%s" id="%i">\n', nodeList{i}, i);
        
        % write attributes from past xgmml
        for j = 1:length(nodeAttributes{index}) % loop over each attribute
            if length(nodeAttributes{index}) == 1 % if only 1 attribute, they are saved differently in the structure array
                name = nodeAttributes{index}{1}.att.Attributes.name;
                type = nodeAttributes{index}{1}.att.Attributes.type;
                value = nodeAttributes{index}{1}.att.Attributes.value;
                fprintf(fid, '<att type="%s" name="%s" value="%s"/>\n',type, name, value);
            else
                name = nodeAttributes{index}{j}.Attributes.name;
                type = nodeAttributes{index}{j}.Attributes.type;
                value = nodeAttributes{index}{j}.Attributes.value;
                fprintf(fid, '<att type="%s" name="%s" value="%s"/>\n',type, name, value);
            end
        end
        
        % write graphics from past xgmml
        g = specGraphics{index}.Attributes;
        
        fprintf(fid, '<graphics type="%s" h="%s" w="%s" x="%s" y="%s" fill="%s" width="%s" outline="%s" cy:nodeTransparency="%s" cy:nodeLabelFont="%s" cy:nodeLabel="%s" cy:borderLineType="%s"/>\n',...
            g.type, g.h, g.w, g.x, g.y, g.fill, g.width, g.outline, g.cy_colon_nodeTransparency, g.cy_colon_nodeLabelFont, ...
            g.cy_colon_nodeLabel, g.cy_colon_borderLineType);
        
        % close node
        fprintf(fid, '</node>\n');
        
    else % write with defaults
        id(end+1)=i;
        fprintf(fid, '<node label="%s" id="%i">\n', nodeList{i}, i);
        fprintf(fid, '<att type="string" name="canonicalName" value="%s"/>\n', nodeLabel{i});
        fprintf(fid, '<att type="string" name="Type" value="%s"/>\n', typeList{i});
        fprintf(fid, '<att type="string" name="HyperEdge.EntityType" value="RegularNode"/>\n');
        
        % write the default graphics based on node info
        switch typeList{i}
            case ''
                fprintf(fid, '<graphics type="RECTANGLE" h="30" w="70" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-14" cy:nodeLabel="%s" cy:borderLineType="solid"/>\n', nodeLabel{i});
            case 'connector'
                fprintf(fid, '<graphics type="ELLIPSE" h="28" w="28" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-10" cy:nodeLabel="AND" cy:borderLineType="solid"/>\n');
            case 'mRNA'
                fprintf(fid, '<graphics type="HEXAGON" h="40" w="85" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-14" cy:nodeLabel="%s" cy:borderLineType="solid"/>\n', nodeLabel{i});
            case 'phenotype'
                fprintf(fid, '<graphics type="HEXAGON" h="40" w="85" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-14" cy:nodeLabel="%s" cy:borderLineType="solid"/>\n', nodeLabel{i});
            case 'protein'
                fprintf(fid, '<graphics type="RECTANGLE" h="30" w="70" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-14" cy:nodeLabel="%s" cy:borderLineType="solid"/>\n', nodeLabel{i});
            case 'smallMolecule'
                fprintf(fid, '<graphics type="ELLIPSE" h="40" w="40" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-14" cy:nodeLabel="%s" cy:borderLineType="solid"/>\n', nodeLabel{i});
            case 'intermediate'
                fprintf(fid, '<graphics type="ELLIPSE" h="20" w="20" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-8" cy:nodeLabel="INT" cy:borderLineType="solid"/>\n');
            otherwise
            fprintf(fid, '<graphics type="RECTANGLE" h="30" w="70" fill="#ffffff" width="3" outline="#000000" cy:nodeTransparency="1.0" cy:nodeLabelFont="Default-0-14" cy:nodeLabel="%s" cy:borderLineType="solid"/>\n', nodeLabel{i});
        end
        fprintf(fid, '</node>\n');
    end
end

% write each edge
for i = 1:length(rcnList) % rcnList was generated from CNA model
    % parse out the reactant and product, then find the indexes of each in specID,
    % and assign the source and target IDs saved earlier
    rxnsplit = strsplit(rcnList{i}, '\t');
    reactant = rxnsplit{1};
    interactionType = rxnsplit{2};
    product = rxnsplit{3};
    
    rcnCmpStr = sprintf('%s %s %s', reactant, interactionType, product);
    if refExists && ismember(rcnCmpStr, xmledgeID) % if match, retain previous formatting
        [~, index] = ismember(rcnCmpStr, xmledgeID);% matching from previousl xgmml
        
        % need to write the initial edge tag with appropriate source and
        % target
        
        sourceID = find(strcmp(reactant, nodeList)); % ids made in order of nodeList
        targetID = find(strcmp(product, nodeList));
        fprintf(fid, '<edge label="%s" source="%i" target="%i">\n', rcnList{i}, sourceID, targetID);
        
        % write the attributes
        for j = 1:length(edgeAttributes{index})
            name = edgeAttributes{index}{j}.Attributes.name;
            type = edgeAttributes{index}{j}.Attributes.type;
            value = edgeAttributes{index}{j}.Attributes.value;
            fprintf(fid, '<att type="%s" name="%s" value="%s"/>\n',type, name, value);
        end
        
        % write the graphics
        g = edgeGraphics{index}.Attributes;
        
        fprintf(fid, '<graphics width="%s" fill="%s" cy:sourceArrow="%s" cy:targetArrow="%s" cy:sourceArrowColor="%s" cy:targetArrowColor="%s" cy:edgeLabelFont="%s" cy:edgeLabel="%s" cy:edgeLineType="%s" cy:curved="%s">\n',...
            g.width, g.fill, g.cy_colon_sourceArrow, g.cy_colon_targetArrow,  g.cy_colon_sourceArrowColor, g.cy_colon_targetArrowColor, g.cy_colon_edgeLabelFont, g.cy_colon_edgeLabel, g.cy_colon_edgeLineType, g.cy_colon_curved);
        
        if isfield(edgeGraphics{index}, 'att'); % if edge bends are present
            fprintf(fid, '<att name="edgeBend">\n');
            if length(edgeGraphics{index}.att.att) == 1 % indexed differently if length 1
                x = edgeGraphics{index}.att.att.Attributes.x;
                y = edgeGraphics{index}.att.att.Attributes.y;
                fprintf(fid, '<att name="handle" x="%s" y="%s"/>\n', x, y);
            else % length greater than 1
                for j = 1:length(edgeGraphics{index}.att.att)
                    x = edgeGraphics{index}.att.att{j}.Attributes.x;
                    y = edgeGraphics{index}.att.att{j}.Attributes.y;
                    fprintf(fid, '<att name="handle" x="%s" y="%s"/>\n', x, y);
                end
            end
            fprintf(fid, '</att>\n');
        end
        fprintf(fid, '</graphics>\n');
        
    else % write with defaults
        reactantIndex = find(strcmp(reactant, nodeList));
        productIndex = find(strcmp(product, nodeList));
        
        fprintf(fid, '<edge label="%s" source="%i" target="%i">\n', rcnList{i}, reactantIndex, productIndex);
        fprintf(fid, '<att type="string" name="canonicalName" value="%s"/>\n', rcnList{i});
        
        interactionType(1) = []; % remove parentheses from string
        interactionType(end) = [];
        fprintf(fid, '<att type="string" name="interaction" value="%s" cy:editable="false"/>\n', interactionType);
        
        % write the default graphics
        % inhibitor arrow = 6 for activating, 15 for inhibiting (Cytoscape
        % syntax)
        if strcmp(interactionType, '1') % 1 for activating, -1 for inhibiting
            arrow = 6;
        else
            arrow = 15;
        end
        fprintf(fid, '<graphics cy:targetArrow="%i"/>\n', arrow);
    end
    
    % close the edge
    fprintf(fid, '</edge>');
end

% close the graph
fprintf(fid, '</graph>');

fclose(fid);
