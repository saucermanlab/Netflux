function Netflux
% Launches Netflux GUI
% Version: 0.09d

global w n K tau ymax y0 specID reactionIDs reactionRules paramList ODElist CNAmodel tstep tUnit tUnitLabel myAxes

% if (isdeployed) %if using MCR *** IS THIS NEEDED??

%% setup the gui
%%
myGui = gui.manualgui;
set(gcf,'Name','Netflux')
set(gcf,'Position',[0 0 920 540]);
myGui.BackgroundColor = [.8 .9 .9];
set(myGui.UiHandle, 'Resize', 'on');

% installation
p = fileparts(which('Netflux.m'));
addpath(genpath(fullfile(p,'utilities')));

p2 = fileparts(which('Netflux.m'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','poi-3.8-20120326.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','poi-ooxml-3.8-20120326.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','poi-ooxml-schemas-3.8-20120326.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','xmlbeans-2.3.0.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','dom4j-1.6.1.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','stax-api-1.0.1.jar'));

%Create Menus
file_menu = uimenu('Label','&File');
            uimenu(file_menu,'Label', 'Open Model','Callback',@openModel, 'Accelerator','N');    
            uimenu(file_menu,'Label','Export Data','Callback',@dataSheet,'Separator','on','Accelerator','D');
            cy = uimenu(file_menu,'Label','Export Cytoscape');
            uimenu(cy,'Label','As SIF','Callback',@cytoscapeSIF,'Accelerator','Y');
            uimenu(cy,'Label','As XGMML','Callback',@cytoscapeXGMML,'Accelerator','X');
            uimenu(file_menu,'Label','Export MATLAB ODE','Callback',@exportODE,'Accelerator','O');
            uimenu(file_menu,'Label', 'Exit','Callback','close(gcf)', 'Accelerator','Z','Separator','on');    
tools_menu = uimenu('Label', '&Tools');
            uimenu(tools_menu,'Label','Convert SBML-QUAL','Callback',@convertSBML, 'Accelerator', 'B');
            uimenu(tools_menu,'Label','Convert SIF','Callback',@convertSIF, 'Accelerator', 'F');
            uimenu(tools_menu,'Label','Copy Plot','Callback',@copyPlot, 'Accelerator','P', 'Separator','on');
help_menu = uimenu('Label','&Help');
            uimenu(help_menu,'Label','About Netflux', 'Callback',@about);


%% Column 1 elements
%% Simulation Label
simulationLabel = gui.label('Simulation',myGui);
simulationLabel.Font.size = 12;
simulationLabel.Font.weight = 'bold';
simulationLabel.TopMargin = 2;
simulationLabel.BottomMargin = 2; 

%% Simulation time
tEnd = gui.editnumber('Simulation time:',myGui);
tEnd.Value = 10;
tEnd.ValueChangedFcn = @updateTend;
tstepLabel = gui.editnumber('Time step:',myGui);
tstepLabel.Value = 0.1;
tstepLabel.ValueChangedFcn = @updateTstep;

speciesListbox = gui.listbox('Species to plot:',{' '},myGui); 
dummyLabel5 = gui.label('Status',myGui);
dummyLabel5.Font.size = 12;
dummyLabel5.Font.weight = 'bold';
statusLabel = gui.listbox('',{' '},myGui);
statusLabel.MenuItems = 'Netflux started! Please open a model';
statusLabel.Value = [];
goButton = gui.pushbutton('Simulate!',myGui);
goButton.ValueChangedFcn = @start;
plotButton = gui.pushbutton('Plot',myGui);
plotButton.ValueChangedFcn = @plotData;
resetPButton = gui.pushbutton('Reset Parameters',myGui);
resetPButton.ValueChangedFcn = @resetParameters;
resetButton = gui.pushbutton('Reset Simulation',myGui);
resetButton.ValueChangedFcn = @resetSimulation;
% dummyLabel1 = gui.label(''); %creates spaces


%% Column 2 elements
% species list/parameters
speciesLabel = gui.label('Species Parameters',myGui);
speciesLabel.Font.size = 12;
speciesLabel.Font.weight = 'bold';
speciesLabel.TopMargin = 2;
speciesLabel.BottomMargin = 2;
 
speciesList = ' '; 
tauLabel = gui.slider('tau (units:              ):',[1e-9 100],myGui);           %tau
tauLabel.ValueChangedFcn = @updateTauWeight;
tUnitLabel = gui.edittext('',myGui);
tUnitLabel.ValueChangedFcn = @updateTunit;
speciesMenu = gui.textmenu('Species List:',speciesList,myGui);
speciesMenu.ValueChangedFcn = @updateDisplayedSpeciesParams;
y0Label = gui.slider('yinit:',[0 10],myGui);           %y0
y0Label.ValueChangedFcn = @updateY0Weight;
yLabel = gui.slider('ymax:',[0 10],myGui); 
yLabel.ValueChangedFcn = @updateYWeight;

% reaction list/parameters
reactionLabel = gui.label('Reaction Parameters',myGui);
reactionLabel.Font.size = 12;
reactionLabel.Font.weight = 'bold';
reactionLabel.TopMargin = 2;
reactionLabel.BottomMargin = 2;
reactionList = ' ';
reactionMenu = gui.textmenu('Reaction list:',reactionList,myGui);
reactionMenu.ValueChangedFcn = @updateDisplayedReactionParams;
wLabel = gui.slider('weight:',[0 1],myGui);          %weight
wLabel.ValueChangedFcn = @updateWWeight;
nLabel = gui.slider('n:',[.5 5],myGui);             %n
nLabel.ValueChangedFcn = @updateNWeight;
kLabel = gui.slider('EC50:',[0 5],myGui);             %EC50
kLabel.ValueChangedFcn = @updateKWeight;
tNow = 0;
tCum = []; yCum = [];
tspan = [tNow,tEnd.Value];
options = [];
count = 0; 

%% explicitly position the widgets

% Column 1
% lm = left margin, bm = bottom margin
lm = 15;
bm = 12;
statusLabel.Position = struct('x',lm,'y',bm+0,'width', 360, 'height', 90); % status listbox
dummyLabel5.Position = struct('x', lm,  'y', bm+85, 'width', 100); % label for status listbox
resetButton.Position = struct('x', lm,  'y', bm+130-2, 'width', 120,'height',20); % button
resetPButton.Position = struct('x', lm,  'y', bm+150-2, 'width', 120,'height',20); %button 
plotButton.Position = struct('x', lm,  'y', bm+170-2, 'width', 120,'height',20);% button
goButton.Position = struct('x', lm,  'y', bm+190-2, 'width', 120,'height',20); % button
speciesListbox.Position = struct('x', lm,  'y', bm+200-5, 'width', 120, 'height',200); % specList
tstepLabel.Position = struct('x', lm,  'y', bm+410-7, 'width', 120,'height',40); % enter tstep
tEnd.Position = struct('x', lm,  'y', bm+450, 'width', 120,'height',40); % enter sim time
simulationLabel.Position = struct('x', lm,  'y', bm+493, 'width', 120); % top label
% add a test comment
% Column 2
col2 = 185;
speciesLabel.Position = struct('x', col2,  'y', bm+493, 'width', 200); % top label
speciesMenu.Position = struct('x',col2, 'y', bm+450, 'width', 182,'height',40); % pulldown 1
tauLabel.Position = struct('x',col2, 'y', bm+410-8, 'width', 175,'height',40); % slider 1
tUnitLabel.Position = struct('x', col2+62, 'y', bm+410+25-9, 'width', 30, 'height',40); % tUnit
y0Label.Position = struct('x',col2, 'y', bm+370-8, 'width', 175,'height',40); % slider 1
yLabel.Position = struct('x',col2, 'y', bm+330-8, 'width', 175,'height',40); % slider 
reactionLabel.Position = struct('x',col2, 'y', bm+290-5, 'width', 205); % Middle label
reactionMenu.Position = struct('x',col2, 'y', bm+250, 'width', 182,'height',40); % pulldown2
wLabel.Position = struct('x',col2, 'y', bm+210-2, 'width', 175,'height',40); % slider2
nLabel.Position = struct('x',col2, 'y', bm+170-2, 'width', 175,'height',40); % slider2
kLabel.Position = struct('x',col2, 'y', bm+130-2, 'width', 175,'height',40); % slider2

% create and position the axes
myAxes = axes('units', 'pixels', 'position', [480 80 410 400]);
%Needs to update figure after it is drawn
tUnitLabel.Value = 'sec';
ylabel('Fractional Species Activation');
%% GUI subfunctions
    function updateTend(hWidget)
        tspan = [tNow tNow+tEnd.Value];
    end
    function updateTstep(hWidget)
        tstep = tstepLabel.Value;
    end
    function updateTunit(hWidget)
        tUnit = tUnitLabel.Value;
        tEnd.Label = sprintf('Simulation time (%s):',tUnit);
        tstepLabel.Label = sprintf('Time step (%s):',tUnit);
        xlabel(sprintf('Time (%s)', tUnit))
        %insert a test 
    end
    function updateDisplayedSpeciesParams(hWidget)  
        selectedSpe = ismember(speciesList,speciesMenu.Value); 
        tauLabel.Value = tau(selectedSpe);
        yLabel.Value = ymax(selectedSpe);      
        y0Label.Value = y0(selectedSpe);
    end
    function updateDisplayedReactionParams(hWidget)  
        selectedRcn = ismember(reactionList,reactionMenu.Value); 
        kLabel.Value = K(selectedRcn);
        nLabel.Value = n(selectedRcn);
        wLabel.Value = w(selectedRcn);               
    end
    function updateY0Weight(hWidget)
        selectedSpe = ismember(speciesList,speciesMenu.Value);
        y0(selectedSpe) = y0Label.Value;
    end
    function updateYWeight(hWidget)
        selectedSpe = ismember(speciesList,speciesMenu.Value);
        ymax(selectedSpe) = yLabel.Value;          
    end
    function updateTauWeight(hWidget)
        selectedSpe = ismember(speciesList,speciesMenu.Value);
        tau(selectedSpe) = tauLabel.Value;                 
    end
    function updateWWeight(hWidget)
        selectedRcn = ismember(reactionList,reactionMenu.Value);        
        w(selectedRcn) = wLabel.Value;               
    end
    function updateNWeight(hWidget)
        selectedRcn = ismember(reactionList,reactionMenu.Value);                 
        n(selectedRcn) = nLabel.Value;      
    end
    function updateKWeight(hWidget) %EC50
        selectedRcn = ismember(reactionList,reactionMenu.Value);         
        K(selectedRcn) = kLabel.Value;   
    end
    function resetParameters(hWidget)
       [w,n,K,tau,ymax,y0] = paramList{:};       
       updateDisplayedReactionParams;
       updateDisplayedSpeciesParams;
       statusLabel.MenuItems = 'Parameters have been reset!';
       statusLabel.Value = [];
    end  
    function start(hWidget)
        if (K.^n < .5)
            statusLabel.MenuItems = 'Warning: EC50 and n combinations are negative';
        end
        runSimulation;
    end
    function runSimulation(hWidget)
        signal = 1;
        if isequal(signal,1) %shows start of simulation
            statusLabel.MenuItems = 'Simulation running...';
            statusLabel.Value = [];
        end
        drawnow
        rpar = [w;n;K];         %Reaction Parameters
        params = {rpar,tau,ymax,specID};
        [t,y]=ode23(@util.ODE,tspan,y0,options,params,ODElist);
        
        statusLabel.MenuItems = 'Interpolating...';
        statusLabel.Value = [];
        drawnow
        % interpolate to equally spaced time points
        x = (tNow:tstep:tspan(end))';
        yi = interp1(t,y,x,'pchip');
        t = x;
        y = yi;

        tNow = t(end);
        updateTend;
        y0 = y(end,:);         
        if count < 1
             tCum = [tCum;t];
             yCum = [yCum;y];
        else
            tCum = [tCum; t(2:length(t))];   % I want to remove the 1st entry
            sizeY = size(y);
            sizeY = sizeY(1);
            yCum = [yCum; y(2:sizeY,:)]; % then concat to the end of the cumulative 
        end
        count = count + 1; 
        % plot results
        selectedVars = ismember(specID,speciesListbox.Value);
        set(gcf,'DefaultLineLineWidth',1.7); % set the width of the lines in the plot
        plot(tCum,yCum(:,selectedVars)); 
        xlabel(sprintf('Time (%s)',tUnit)); ylabel('Fractional species activation');
        legend(speciesListbox.Value);
        signal = 2;
        if ~isequal(signal,1) 
            statusLabel.MenuItems = 'Simulation Successful!'; 
            statusLabel.Value = [];
        end
        updateDisplayedSpeciesParams
    end
    function plotData(hWidget)
        selectedVars = ismember(specID,speciesListbox.Value);
        if(isempty(yCum))
            statusLabel.MenuItems = 'No Plot: please ''Simulate'' first'; 
            statusLabel.Value = [];
        else
            plot(tCum,yCum(:,selectedVars));        
            xlabel(sprintf('Time (%s)',tUnit)); ylabel('Fractional species activation');
            legend(speciesListbox.Value);
            statusLabel.MenuItems = 'Plot Successful!'; 
            statusLabel.Value = [];
        end
    end
    function resetSimulation(hWidget)
        tNow = 0;
        updateTend;   
        tCum = [];
        yCum = [];
        count = 0; 
        y0 = paramList{6};
        plot(0,0); axis([0 1 0 1]); 
        xlabel(sprintf('Time (%s)',tUnit));ylabel('Fractional species activation');
        updateDisplayedSpeciesParams;
        updateDisplayedReactionParams;
        statusLabel.MenuItems = 'Simulation has been reset';
        statusLabel.Value = [];
    end

%% menu functions
    function copyPlot(obj,e) 
        ax1 = gca;
        figure('menubar','none','Toolbar','figure');
        copyobj(allchild(ax1),gca);
        statusLabel.MenuItems = 'Plot Copied!';
        statusLabel.Value = [];
    end
    function openModel(obj,e)
        try
            
            [fname,pathname,filterindex]=uigetfile({'*.xls;*.xlsx', 'Excel Files'},'Open XLS network reconstruction');
            if ~isequal(fname,0)
                
                xlsfilename = [pathname fname];
                
                statusLabel.MenuItems = 'Loading model...'; drawnow;
                [specID,reactionIDs,reactionRules,paramList,ODElist,CNAmodel, error] = util.xls2Netflux(strrep(fname,'.xls',''),xlsfilename);
                [w,n,K,tau,ymax,y0] = paramList{:};
                speciesListbox.MenuItems = specID;
                speciesList = specID;
                speciesMenu.MenuItems = speciesList;
                reactionList = cellfun(@(x,y) [x,': ',y],reactionIDs,reactionRules,'UniformOutput',false);
                reactionMenu.MenuItems = reactionList;
                tauLabel.ValueRange = [1e-9 1e9];
                yLabel.ValueRange = [0 10];
                y0Label.ValueRange = [0 10];
                nLabel.ValueRange = [.5 5];
                kLabel.ValueRange = [0 5];
                
                errsignal = false;
                if ~isempty(error{1}) || ~isempty(error{2}) %check to see if error passed from xls2Netflux exists
                    statusLabel.MenuItems = error; % display the errors in the status window
                    statusLabel.Value = [];
                    errsignal = true;
                    updateDisplayedSpeciesParams;
                    updateDisplayedReactionParams;
                    updateTstep;
                end
                
                if ~errsignal
                    resetParameters;
                    resetSimulation;
                    updateTstep;
                    a = 'New model, ';
                    b = ', loaded!';
                    z = horzcat(a,fname,b);
                    statusLabel.MenuItems = z;
                    statusLabel.Value = [];
                end
                errsignal = false;
            else
                statusLabel.MenuItems = 'Excel import canceled';
            end
            
        catch e
            errorstr = {'Error reading file, try resaving as new .xlsx',...
                e.identifier, e.message,'line:', e.stack.name,num2str(e.stack.line)}
            statusLabel.MenuItems = errorstr;
        end
        
    end
    function convertSBML(obj,e)
        fnames = SBMLgui;
        if fnames.userCanceled && ~fnames.error
            statusLabel.MenuItems = 'Conversion canceled'; drawnow;
            statusLabel.Value = [];
        else
            xmlname = fnames.xml;
            outputfolder = fnames.outputfolder;
            statusLabel.MenuItems = 'Converting SBML...';
           try
                drawnow;
                outputfname = util.sbml2sif(xmlname, outputfolder);
                statusLabel.MenuItems = {'Conversion Complete', 'Saved to:',outputfname};
           catch e
                statusLabel.MenuItems = {'Export Failed', e.message};
                drawnow;
           end
        end
    end
    function convertSIF(obj,e)
        %prompt for filename and reference name
        fnames = SIFgui;
        if fnames.userCanceled
            statusLabel.MenuItems = 'Conversion canceled'; drawnow;
            statusLabel.Value = [];
        else
            sifname = fnames.sif;
            outputname = fnames.outputname;
            statusLabel.MenuItems = 'Converting SIF...'; drawnow;
            try
                util.importsif(fnames.sif, fnames.outputname);
                statusLabel.MenuItems = {'Model saved as:', fnames.outputname}; drawnow;
            catch e
                statusLabel.MenuItems = {'Export Failed', e.identifier}; drawnow;
                throw(e)
            end
        end
    end
    function dataSheet(obj,e)
        %check to see if simulation has run
        if (isempty(tCum))
            statusLabel.MenuItems = 'Need to simulate the model first';  
            statusLabel.Value = [];
        else        
            %prompt for filename
            default = 'Data Sheet';  
            [nfname,pathname,filterindex]=uiputfile('*.txt','Save Data as... (no extension)',[default]);
            
            if isequal(pathname,0) %check to see if saving was canceled
                statusLabel.MenuItems = 'Data export canceled';
                statusLabel.Value = [];
            else
                nfname = fullfile(pathname,nfname);
                nfilename = nfname; 
                
                % create labeled time values
                timeLabeli = tCum;                   
                timeLabeli = cellfun(@num2str,num2cell(timeLabeli),'UniformOutput',false);
                tHeader = {'T'};
                timeLabel = strcat(tHeader,timeLabeli);
                header1 = {'Species_Name'};
                write = cat(2,header1,timeLabel');  %concatenates "species name" and time points        
                tDCum = tCum;  %D stands for Data
                yDCum = yCum;         
                for j = 1:length(specID)                               
                    yi = yCum;           
                    %yi = round(yi*10^4)./10^4; %rounds the output to 4 decimal places
                    yi = num2cell(yi);
                    label = specID(j);
                    label = horzcat(label,yi(:,j)'); % concats species header to the y values from t0 to tend 
                    write = cat(1,write,label);
                end
                util.textwrite(nfilename,write);
                a = 'Data written to ';
                z = horzcat(a,strrep(nfilename,pathname,''));
                statusLabel.MenuItems = z;
                statusLabel.Value = [];
            end
        end
    end
    function cytoscapeSIF(obj,e)
        if ~isempty(specID)
            %prompt for filename
            default = 'Cytoscape';
            [nfname,pathname,filterindex]=uiputfile('*.*','Save Cytoscape as... (no extension)',[default]);
            if isequal(pathname,0)
                statusLabel.MenuItems = 'Cytoscape export canceled';
                statusLabel.Value = [];
            else
                CNAmodel.net_var_name = nfname;
                util.Netflux2sif(CNAmodel,pathname);
                a = 'Cytoscape exported to ';
                b = '.sif';
                z = horzcat(a,CNAmodel.net_var_name,b);
                statusLabel.MenuItems = z;
                statusLabel.Value = [];
            end
        else
            statusLabel.MenuItems = 'Need to open model first';
        end
    end
    function cytoscapeXGMML(obj,e)
        if ~isempty(specID)
            %prompt for filename and reference name
            default = 'Cytoscape';
            fnames = XGMMLgui; % put in gui folder later?
            
            if fnames.userCanceled
                statusLabel.MenuItems = 'Cytoscape export canceled'; drawnow;
                statusLabel.Value = [];
            else
                outputfname = fnames.output;
                referencefname = fnames.reference;
                statusLabel.MenuItems = 'Exporting to XGMML...'; drawnow;
                
                try
                    if strcmp(referencefname, ''); % if reference not specified
                        util.Netflux2xgmml(CNAmodel, outputfname);
                    else
                        util.Netflux2xgmml(CNAmodel, outputfname, referencefname); % if reference specified
                    end
                    statusLabel.MenuItems = {'Model exported to:', outputfname}; drawnow;
                catch e
                    statusLabel.MenuItems = {'Export Failed', e.identifier}; drawnow;
                    throw(e)
                end
            end
        else
            statusLabel.MenuItems = 'Need to open model first';
        end
    end
    function exportODE(~,e)
        %prompt for filename
        default = 'NetfluxODE';
        [nfname,pathname,filterindex]=uiputfile('*.m','Save Data as...',[default]);
        nfilename = fullfile(pathname,nfname);

        commandLine = util.exportODE(specID,paramList,ODElist);
        util.textwrite(nfilename,commandLine);
        statusLabel.MenuItems = 'Matlab ODEfile exported!'; 
        statusLabel.Value = [];
    end
    function about(obj,e)
        mFigure = figure();
        set(mFigure,'menubar','none','numbertitle','off','name','About Netflux','windowstyle','normal','resize','off');
        set(mFigure, 'Position',[380 378 300 300]);
        set(mFigure,'Color','w');
        colorOfFigureWindow = get(mFigure,'Color');
        
        titleTextBox = uicontrol ('style','text','BackgroundColor',colorOfFigureWindow);
        set(titleTextBox,'Position', [5 200 300 75]);
        set(titleTextBox,'horizontalalignment','left','fontweight','bold','fontsize',18,'String','Netflux');
        
        versionTextBox = uicontrol('style','text','BackgroundColor',colorOfFigureWindow);
        set(versionTextBox,'Position', [5 175 300 75]);
        set(versionTextBox,'horizontalalignment','left','fontangle','italic','fontsize',12,'String','Current Version: 1.0');
        
        developerTextBox = uicontrol('style','text','BackgroundColor',colorOfFigureWindow);
        set(developerTextBox,'Position', [2 90 300 75]);
        set(developerTextBox,'horizontalalignment','center','fontsize',12,'String','Developed by Alex Paap, Stephen Dang, and Jeff Saucerman at the University of Virginia');
        
%         labelStr = '<html><center><a href="">Website: https://github.com/saucerman/Netflux';
%         cbStr = 'web(''https://github.com/saucerman/Netflux'');';
%         hButton = uicontrol('string',labelStr,'pos',[50,65,200,35],'callback',cbStr);
%         set(hButton,'BackgroundColor',colorOfFigureWindow);
%         jButton = util.findjobj(hButton); % get FindJObj from the File Exchange
%         jButton.setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));        
%         jButton.setBorder([]);
%         
        labelStr2 = '<html><center><a href="">Website and documentation: <br> https://github.com/saucerman/Netflux';
        cbStr2 = 'web(''https://github.com/saucerman/Netflux'');';
        hButton2 = uicontrol('string',labelStr2,'pos',[25,20,250,35],'callback',cbStr2);
        set(hButton2,'BackgroundColor',colorOfFigureWindow);
        jButton2 = util.findjobj(hButton2); % get FindJObj from the File Exchange
        jButton2.setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));       
        jButton2.setBorder([]);
        
    end
end
