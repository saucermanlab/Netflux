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
%   SBGN graphics are generated from the "type" column of the Species sheet
%   in the Netflux Excel file. The supported categories are protein, mRNA,
%   smallMolecule, phenotype, connector, and intermediate.
%   
%   Updated June 8, 2017 by Xiaji (Astor) Liu (xliu@virginia.edu) 
%   Now compatible with reference XGMML from Cytoscape 3.4.0. Node and edge
%   Attributes/properties in Cytoscape 3.4.0 are modified and structered
%   differently from Cytoscape 2.8.3. Code has been updated to accomondate
%   the new features. Missing values are substituted with defaults (0 or
%   empty string). Additional attributes (i.e. additional imported values
%   to Cytoscape) can be returned if needed.
%   Put this into folder: Netflux-master/Netflux/+util and either change
%   replace util.Netflux2xgmml with util.Netflux2xgmml_cy3 in Netflux.m or
%   replace Netflux.m with Netflux_cy3.m to start Netflux GUI. 


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
            if i==1
                for vi=1:length(nodeAttributes{i})
                    vname{vi}=nodeAttributes{i}{vi}.Attributes; % return a cell of structs containing a list of the attributes from reference
                end
            else
            end
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
                if isfield(nodeAttributes{index}{1}.att.Attributes,'value')==1
                    value = nodeAttributes{index}{1}.att.Attributes.value;
                else % fill in missing values
                    if strcmp(type,'string')==1
                        value = ' ';
                    elseif strcmp(type,'real')==1
                        value = '0.0';
                    elseif strcmp(type,'integer')==1
                        value = '0';
                    elseif strcmp(type,'boolean')==1
                        value = '0';
                    end
                end
                cytype = nodeAttributes{index}{1}.att.Attributes.cy_colon_type;
                fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
            elseif ismember(nodeAttributes{index}{j}.Attributes.name,{'shared name' 'canonicalName' ...
                    'name' 'Type' 'HyperEdge.EntityType'})==1 % only returning necessary attributes
%             else % uncomment this line if returning all attributes
%             from reference
                name = nodeAttributes{index}{j}.Attributes.name;
                type = nodeAttributes{index}{j}.Attributes.type;
                if isfield(nodeAttributes{index}{j}.Attributes,'value')==1
                    value = nodeAttributes{index}{j}.Attributes.value;
                else
                    if strcmp(type,'string')==1
                        value = ' ';
                    elseif strcmp(type,'real')==1
                        value = '0.0';
                    elseif strcmp(type,'integer')==1
                        value = '0';
                    elseif strcmp(type,'boolean')==1
                        value = '0';
                    end
                end
                cytype = nodeAttributes{index}{j}.Attributes.cy_colon_type;
                fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
            end
        end
        
        % write graphics from past xgmml
        g = specGraphics{index}.Attributes;
        
        % write graphics header
        fprintf(fid, '<graphics type="%s" h="%s" w="%s" x="%s" y="%s" z="%s" fill="%s" width="%s" outline="%s">\n',... 
            g.type, g.h, g.w, g.x, g.y, g.z, g.fill, g.width, g.outline);
        
%         % write graphic attributes
%         for j = 1:length(specGraphics{index}.att) % loop over each attribute
%             if length(specGraphics{index}.att) == 1 % if only 1 attribute, they are saved differently in the structure array
%                 name = specGraphics{index}.att{1}.att.Attributes.name;
%                 type = specGraphics{index}.att{1}.att.Attributes.type;
%                 if isfield(specGraphics{index}.att{1}.att.Attributes,'value')==1
%                     value = specGraphics{index}.att{1}.att.Attributes.value;
%                 else
%                     value = '';
%                 end
%                 cytype = specGraphics{index}.att{1}.att.Attributes.cy_colon_type;
%                 fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
%             else
%                 name = specGraphics{index}.att{j}.Attributes.name;
%                 type = specGraphics{index}.att{j}.Attributes.type;
%                 if isfield(specGraphics{index}.att{j}.Attributes,'value')==1
%                     value = specGraphics{index}.att{j}.Attributes.value;
%                 else
%                     value = '';
%                 end
%                 cytype = specGraphics{index}.att{j}.Attributes.cy_colon_type;
%                 fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
%             end
%          end
            
        % close graphics
        fprintf(fid, '</graphics>\n');
        % close node
        fprintf(fid, '</node>\n');
        
    else % write with defaults
        id(end+1)=i;
        fprintf(fid, '<node label="%s" id="%i">\n', nodeList{i}, i);
        for j = 1:length(vname) % loop over each attribute
            if strcmp(vname{j}.name,'shared name')==1
                fprintf(fid, '<att type="string" name="shared name" value="%s" cy:type="String"/>\n', nodeList{i});
            elseif strcmp(vname{j}.name,'canonicalName')==1
                fprintf(fid, '<att type="string" name="canonicalName" value="%s" cy:type="String"/>\n', nodeLabel{i});
            elseif strcmp(vname{j}.name,'name')==1
                fprintf(fid, '<att type="string" name="name" value="%s" cy:type="String"/>\n', nodeList{i});
            elseif strcmp(vname{j}.name,'Type')==1
                fprintf(fid, '<att type="string" name="Type" value="%s" cy:type="String"/>\n', typeList{i});
            else
                fprintf(fid, '<att type="string" name="HyperEdge.EntityType" value="RegularNode" cy:type="String"/>\n');
% %  uncomment the following block if returning default values for all the
% % attributes in reference
%                 name = vname{j}.name;
%                 type = vname{j}.type;
%                 if isfield(vname{j},'value')==1
%                     value = vname{j}.value;
%                 else
%                     if strcmp(type,'string')==1
%                         value = ' ';
%                     elseif strcmp(type,'real')==1
%                         value = '0.0';
%                     elseif strcmp(type,'integer')==1
%                         value = '0';
%                     elseif strcmp(type,'boolean')==1
%                         value = '0';
%                     end
%                 end
%                 cytype = vname{j}.cy_colon_type;
%                 fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
            end
        end
        
        % write the default graphics based on node info
        switch typeList{i}
            case ''
                fprintf(fid, '<graphics type="RECTANGLE" h="30.0" w="70.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            case 'connector'
                fprintf(fid, '<graphics type="ELLIPSE" h="28.0" w="28.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            case 'mRNA'
                fprintf(fid, '<graphics type="HEXAGON" h="40.0" w="85.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            case 'phenotype'
                fprintf(fid, '<graphics type="HEXAGON" h="40.0" w="85.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            case 'protein'
                fprintf(fid, '<graphics type="RECTANGLE" h="30.0" w="70.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            case 'smallMolecule'
                fprintf(fid, '<graphics type="ELLIPSE" h="40.0" w="40.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            case 'intermediate'
                fprintf(fid, '<graphics type="ELLIPSE" h="20.0" w="20.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
            otherwise
            fprintf(fid, '<graphics type="RECTANGLE" h="30.0" w="70.0" fill="#FFFFFF" width="3.0" outline="#000000">\n');
        end
        fprintf(fid, '</graphics>\n');
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
        fprintf(fid, '<edge label="%s" source="%i" target="%i" cy:directed="1">\n', rcnList{i}, sourceID, targetID);
        
        % write the attributes
        for j = 1:length(edgeAttributes{index})
            name = edgeAttributes{index}{j}.Attributes.name;
            type = edgeAttributes{index}{j}.Attributes.type;
            if isfield(edgeAttributes{index}{j}.Attributes,'value')==1
                value = edgeAttributes{index}{j}.Attributes.value;
            else
                value = '';
            end
            cytype = edgeAttributes{index}{j}.Attributes.cy_colon_type;
            fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
        end
        
        % write the graphics
        g = edgeGraphics{index}.Attributes;
        
        % write graphics header
        fprintf(fid, '<graphics width="%s" fill="%s">\n',g.width, g.fill);
        
                % write graphic attributes
                        fprintf(fid, '<att type="string" name="canonicalName" value="%s"/>\n', rcnList{i});
        
        interactionType(1) = []; % remove parentheses from string
        interactionType(end) = [];
        fprintf(fid, '<att type="string" name="interaction" value="%s" cy:editable="false"/>\n', interactionType);
        
                % inhibitor arrow = 6 for activating, 15 for inhibiting (Cytoscape syntax)
        if strcmp(interactionType, '1') % 1 for activating, -1 for inhibiting
            arrow = 'ARROW';
        else
            arrow = 'T';
        end
        fprintf(fid, '<att name="EDGE_TARGET_ARROW_SHAPE" value="%s" type="string" cy:type="String"/>\n', arrow);

% %   returning additional graphics attributes
%         for j = 1:length(edgeGraphics{index}.att) % loop over each attribute
%             if length(edgeGraphics{index}.att) == 1 % if only 1 attribute, they are saved differently in the structure array
%                 name = edgeGraphics{index}.att{1}.att.Attributes.name;
%                 type = edgeGraphics{index}.att{1}.att.Attributes.type;
%                 if isfield(edgeGraphics{index}.att{1}.att.Attributes,'value')==1
%                     value = edgeGraphics{index}.att{1}.att.Attributes.value;
%                 else
%                     value = '';
%                 end
%                 cytype = edgeGraphics{index}.att{1}.att.Attributes.cy_colon_type;
%                 fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
%             else
%                 name = edgeGraphics{index}.att{j}.Attributes.name;
%                 type = edgeGraphics{index}.att{j}.Attributes.type;
%                 if isfield(edgeGraphics{index}.att{j}.Attributes,'value')==1
%                     value = edgeGraphics{index}.att{j}.Attributes.value;
%                 else
%                     value = '';
%                 end
%                 cytype = edgeGraphics{index}.att{j}.Attributes.cy_colon_type;
%                 fprintf(fid, '<att type="%s" name="%s" value="%s" cy:type="%s"/>\n',type, name, value,cytype);
%             end
%         end
        
%         if isfield(edgeGraphics{index}, 'att'); % if edge bends are present
%             fprintf(fid, '<att name="edgeBend">\n');
%             if length(edgeGraphics{index}.att.att) == 1 % indexed differently if length 1
%                 x = edgeGraphics{index}.att.att.Attributes.x;
%                 y = edgeGraphics{index}.att.att.Attributes.y;
%                 fprintf(fid, '<att name="handle" x="%s" y="%s"/>\n', x, y);
%             else % length greater than 1
%                 for j = 1:length(edgeGraphics{index}.att.att)
%                     x = edgeGraphics{index}.att.att{j}.Attributes.x;
%                     y = edgeGraphics{index}.att.att{j}.Attributes.y;
%                     fprintf(fid, '<att name="handle" x="%s" y="%s"/>\n', x, y);
%                 end
%             end
%             fprintf(fid, '</att>\n');
%         end
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
        fprintf(fid, '<graphics width="2.0" fill="#000000">\n');
        % inhibitor arrow = 6 for activating, 15 for inhibiting (Cytoscape
        % syntax)
        if strcmp(interactionType, '1') % 1 for activating, -1 for inhibiting
            arrow = 'ARROW';
        else
            arrow = 'T';
        end
        fprintf(fid, '<att name="EDGE_TARGET_ARROW_SHAPE" value="%s" type="string" cy:type="String"/>\n', arrow);
        fprintf(fid, '</graphics>\n');
    end
    
        % close the edge
    fprintf(fid, '</edge>\n');
end

% close the graph
fprintf(fid, '</graph>');

fclose(fid);
