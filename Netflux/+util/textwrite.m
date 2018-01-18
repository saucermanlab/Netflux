function textwrite(filename,text,delim)
% Writes a 1 or 2D cell array to the specified text file
% syntax: textwrite(filename,text,delim)
%   delim is optional, with default being ' ' for space delimited
%
% note: to read in a text file into a cell array, type
%
% textwrite.m
% Author: JJS   Date: 2/23/2004

if nargin == 2
    delim = ' '; % delimiter between columns
end

outfile = fopen(filename,'wt');
for i = 1:size(text,1)
    for j=1:size(text,2)
        if ~isstr(text{i,j})
            text{i,j}=num2str(text{i,j});
        end
        fprintf(outfile,['%s',delim],text{i,j}); %in order for .sif to work, no spacing
    end
    fprintf(outfile,'\n');
end
fclose(outfile);
