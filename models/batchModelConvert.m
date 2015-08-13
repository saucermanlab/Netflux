cd('C:\Users\amp2hj\Documents\Batch Model Convert');

p2 = fileparts(which('Netflux.m'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','poi-3.8-20120326.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','poi-ooxml-3.8-20120326.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','poi-ooxml-schemas-3.8-20120326.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','xmlbeans-2.3.0.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','dom4j-1.6.1.jar'));
javaaddpath(fullfile(p2,'utilities','20130227_xlwrite','poi_library','stax-api-1.0.1.jar'));

[folders, files]=subdir('C:\Users\amp2hj\Documents\Homo_sapiens');

indFailure = [];
failureName = {};
errors={};
for i = 1:length(folders);
    try
        disp(sprintf('On model %i of %i', i, length(folders)));
        cd('C:\Users\amp2hj\Documents\Batch Model Convert');
        fname = fullfile(folders{i},files{i}{2});
        import = xml2struct(fname);
        name = import.sbml.model.Attributes.name;
        mkdir(name);
        util.sbml2sif(fname,fullfile(cd,name));
        cd('C:\Users\amp2hj\Documents\Batch Model Convert');
   catch e
        indFailure(end+1)=i;
        failureName{end+1} = files{i}{2};
        errors{end+1} = e;
        disp(e.identifier);
   end
end
        
for i = 1:length(indFailure)-6
    movefile(char(folders(indFailure(i))), 'C:\Users\amp2hj\Documents\Failed Models','f');
end
