function stoOut = writeSTO(stoTable, varargin)
% Convert a table with ID data to an sto file
% stoOut = writeSTO(stoTable, varargin)
%
% stoTable : data (first column is header)
% Returns stoOut: the path of the file generated
%
% Optional 
% 'FilePath': file to export (default a tempfile)

    narginchk(1, 6);    
	stoTable = Osim.interpret(stoTable, 'STO');

	p=inputParser;
	addRequired(p,'stoTable',@istable);
    defaultFilePath=[tempname() '.sto'];
    addParameter(p,'FilePath',defaultFilePath,@ischar);
    
	p.parse(stoTable,varargin{:});	
    stoOut=p.Results.FilePath;
    
    if ~endsWith(stoOut, '.sto')
        stoOut = [stoOut '.sto'];
    end
    			
			
    varNames = stoTable.Properties.VariableNames;	
    if (strcmpi(varNames(1),{'Frame'}))
		%This is how the code was originally intended
		% do nothing
        error('Only supports Header column for time');
	elseif (strcmpi(varNames(1),{'Header'}))
		%Adapt the table to be Frame and time		
		varNames(1)={'time'};
    elseif ~strcmpi(varNames(1),{'time'})
		error('Unrecognized table format');
    end
	
    data = stoTable.Variables;
    
    text{1} = sprintf('Inverse Dynamics Generalized Forces\nversion=1\nnRows=%d\nnColumns=%d\ninDegrees=no\nendheader',size(data, 1), size(data, 2));
    text{2} = sprintf('%s\t', strjoin(varNames, '\t'));
	
	
    fh = fopen(stoOut, 'w');
    for i = 1:length(text)
        fprintf(fh, '%s\n', text{i});
    end
    fclose(fh); 
    dlmwrite(stoOut, data, '-append', 'delimiter', '\t', 'precision', 6);
end
