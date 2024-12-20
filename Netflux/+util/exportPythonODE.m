function [commandLine,commandLine2,commandLine3] = exportPythonODE(speciesNames,paramList,CNAmodel,nfilename)
%Exports system of equations to standalone .m files.
% 
%   exportPythonODE.m
%   This function generates the contents of files used for exporting the model 
%   as standalone Python code.
%   Inputs: 
%   paramsList = parameter list
%   speciesNames = list of speciesNames
%   ODElist = list of ODEs 
%   Outputs: 
%   commandLine = cell array containing the ODEs
%   commandLine2 = cell array containing the parameters
%   commandLine3 = cell array containing code for calling ODE solver
%   08/31/2011 by JJS
%   09/28/2017 update by PMT
%   01/15/2018 update by JJS
%   01/15/2018 exportPythonODE.m copied from exportODE.m, currently editing
%   Note: this does not currently generate functional python code
%   07/01/2024 updated by Kaitlyn Wintruba

%% Write file that defines the parameters
[w,n,EC50,tau,ymax,y0] = paramList{:};
commandLine2{1} = sprintf(['# ',nfilename,'_params.py']);
commandLine2{end+1,1} = sprintf('# Automatically generated by Netflux on %s',date);
commandLine2{end+1} = sprintf('import numpy as np\n');
commandLine2{end+1} = sprintf('def loadParams():');     
commandLine2{end+1} = sprintf('\t#species parameters');
commandLine2{end+1} = sprintf(['\tspeciesNames = [',sprintf('\''%s\'',',speciesNames{:}),']']); 
commandLine2{end+1} = sprintf(['\ttau = np.array([',sprintf('%d, ',tau),'])']);
commandLine2{end+1} = sprintf(['\tymax = np.array([',sprintf('%d, ',ymax),'])']);
commandLine2{end+1} = sprintf(['\ty0 = np.array([',sprintf('%d, ',y0),'])\n']); 
commandLine2{end+1} = sprintf('\t# reaction parameters');
commandLine2{end+1} = sprintf(['\tw = np.array([',sprintf('%d, ',w),'])']);
commandLine2{end+1} = sprintf(['\tn = np.array([',sprintf('%d, ',n),'])']);
commandLine2{end+1} = sprintf(['\tEC50 = np.array([',sprintf('%d, ',EC50),'])']);
commandLine2{end+1} = sprintf('\treturn speciesNames, tau, ymax, y0, w, n, EC50');

%% Write the run file that calls the params and ODEfile
commandLine3{1} = sprintf(['# ',nfilename,'_run.py']);
commandLine3{end+1,1} = sprintf('# Automatically generated by Netflux on %s',date);
commandLine3{end+1} = sprintf('\nimport numpy as np');
commandLine3{end+1} = sprintf('from scipy.integrate import ode');
commandLine3{end+1} = sprintf('import matplotlib.pyplot as plt');
commandLine3{end+1} = sprintf(['import ',nfilename]);
commandLine3{end+1} = sprintf(['import ',nfilename,'_params\n']);
commandLine3{end+1} = sprintf(['[speciesNames, tau, ymax, y0, w, n, EC50] = ',nfilename,'_params.loadParams()\n']);     

commandLine3{end+1} = sprintf('# Run single simulation');
commandLine3{end+1} = sprintf('tspan = [0, 10]');
commandLine3{end+1} = sprintf('t = []');
commandLine3{end+1} = sprintf('dt = tspan[1]/150.');
commandLine3{end+1} = sprintf(['r = ode(',nfilename,'.ODEfunc).set_integrator(''vode'', method=''adams'', order=10, rtol=0, atol=1e-6, with_jacobian=False)']);
commandLine3{end+1} = sprintf('r.set_initial_value(y0,tspan[0]).set_f_params(tau,ymax,w,n,EC50)');
commandLine3{end+1} = sprintf('results = np.empty([0,len(speciesNames)])');
commandLine3{end+1} = sprintf('while r.successful() and r.t <= tspan[1]:');
commandLine3{end+1} = sprintf('\tr.integrate(r.t + dt)');
commandLine3{end+1} = sprintf('\tresults = np.append(results,[r.y],axis=0)');
commandLine3{end+1} = sprintf('\tt.append(r.t)');

commandLine3{end+1} = sprintf('\nfig, ax = plt.subplots()');
commandLine3{end+1} = sprintf('ax.plot(t,results)');
commandLine3{end+1} = sprintf('ax.set(xlabel=''Time'',ylabel=''Fractional activation'')');
commandLine3{end+1} = sprintf('ax.legend(speciesNames)');

% commandLine3{end+1} = sprintf('xlabel(''Time (sec)'');\n');
% commandLine3{end+1} = sprintf('ylabel(''Fractional Species Activation'');\n');
% commandLine3{end+1} = sprintf('speciesNames = params{4};\n');
% commandLine3{end+1} = sprintf('legend(speciesNames);');

%% Write the ODEfunc
commandLine{1} = sprintf(['# ',nfilename,'.py']);
commandLine{end+1,1} = sprintf('# Automatically generated by Netflux on %s',date);
commandLine{end+1} = sprintf('import numpy as np');
commandLine{end+1} = 'def ODEfunc(t,y,tau,ymax,w,n,EC50):';
commandLine{end+1} = sprintf('\n\trpar = np.array([w,n,EC50])');

pythonODElist = util.Netflux2pythonODE(CNAmodel); % generate list of python ODEs 
commandLine = [commandLine; pythonODElist]; 
 
%% write utility functions
commandLine{end+1} = sprintf('\n# utility functions\n');
commandLine{end+1} = sprintf('def act(x, rpar):');
commandLine{end+1} = sprintf('\t# Extract parameters from rpar');
commandLine{end+1} = sprintf('\tw = rpar[0]');
commandLine{end+1} = sprintf('\tn = rpar[1]');
commandLine{end+1} = sprintf('\tEC50 = rpar[2]\n');

commandLine{end+1} = sprintf('\t# hill activation function with parameters w (weight), n (Hill coeff), EC50');
commandLine{end+1} = sprintf('\tbeta = ((EC50**n)-1)/(2*EC50**n-1)');
commandLine{end+1} = sprintf('\tK = (beta-1)**(1/n)');
commandLine{end+1} = sprintf('\tfact = w*(beta*x**n)/(K**n+x**n)');
commandLine{end+1} = sprintf('\tif fact > w:');
commandLine{end+1} = sprintf('\t\tfact = w');
commandLine{end+1} = sprintf('\treturn fact\n');

commandLine{end+1} = sprintf('def inhib(x, rpar):');
commandLine{end+1} = sprintf('\t# Extract parameters from rpar');
commandLine{end+1} = sprintf('\tw = rpar[0]');
commandLine{end+1} = sprintf('\t# inverse hill function with parameters w (weight), n (Hill coeff), EC50');
commandLine{end+1} = sprintf('\tfinhib = w - act(x, rpar)');
commandLine{end+1} = sprintf('\treturn finhib\n');

commandLine{end+1} = sprintf('def OR(x, y):');
commandLine{end+1} = sprintf('\t# OR logic gate');
commandLine{end+1} = sprintf('\tz = x + y - x*y');
commandLine{end+1} = sprintf('\treturn z\n');

commandLine{end+1} = sprintf('def AND(w, reactList):');
commandLine{end+1} = sprintf('\t# AND logic gate, multiplying all of the reactants together');
commandLine{end+1} = sprintf('\tif w == 0:');
commandLine{end+1} = sprintf('\t\tz = 0'); 
commandLine{end+1} = sprintf('\telse:');
commandLine{end+1} = sprintf('\t\tp = np.array(reactList).prod()'); 
commandLine{end+1} = sprintf('\t\tz = p/w**(len(reactList)-1)');        
commandLine{end+1} = sprintf('\treturn z\n');
