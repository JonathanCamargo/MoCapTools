function motOut = writeMOT(motTable, varargin)
% Convert a table with forceplate data to an mot file
% motOut = writeMOT(motTable, OPTIONAL)
%
% motTable : data (first column is header)
% Returns motOut: the path of the file generated
%
% Optional 
% 'FilePath': file to export (default a tempfile)
% 'DeviceNames': cell array of devices names for column headers. 

    narginchk(1, 6);
    motTable = Osim.interpret(motTable, 'MOT');

	p=inputParser;
	addRequired(p,'motTable',@istable);
    defaultFilePath=[tempname() '.mot'];
	addParameter(p,'DeviceNames',[],@(x)iscellstr(x) || isstring(x));
    addParameter(p,'FilePath',defaultFilePath,@ischar);
		
	parse(p,motTable,varargin{:});	
    motOut=p.Results.FilePath;
    DeviceNames=p.Results.DeviceNames;
    
    if ~endsWith(motOut, '.mot')
        motOut = [motOut '.mot'];
    end
    
    if  isempty(DeviceNames)
        CUSTOM_LABELS=false;
    else
        CUSTOM_LABELS=true;
    end
			
			
    varNames = motTable.Properties.VariableNames;	
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
	
    fpMOT = true;
    if any(contains(varNames, 'angle'))
        fpMOT = false;		
    end
	
    data = motTable.Variables;
			   
    if fpMOT
        text{1} = motOut;
        text{2} = sprintf('version=1\nnRows=%d\nnColumns=%d\ninDegrees=yes\nendheader',size(data, 1), size(data, 2));
		if CUSTOM_LABELS			
            suffix = ["vx","vy","vz","px","py","pz","moment_x","moment_y","moment_z"];
            newHeaders = compose('%s_%s', string(DeviceNames(:)), suffix)';
            newCols = [varNames(1); newHeaders(:)];
			text{3} = sprintf('%s\t', strjoin(newCols', '\t'));
        else
            text{3} = sprintf('%s\t', strjoin(varNames, '\t'));
		end
    else
        text{1} = sprintf('Coordinates\nversion=1\nnRows=%d\nnColumns=%d\ninDegrees=yes\n',size(data, 1), size(data, 2));
        text{2} = sprintf('Units are S.I. units (second, meters, Newtons, ...\nAngles are in degrees.\n\nendheader');
		text{3} = sprintf('%s\t', strjoin(varNames, '\t'));		
    end
	
	
    fh = fopen(motOut, 'w');
    for i = 1:length(text)
        fprintf(fh, '%s\n', text{i});
    end
    fclose(fh); 
    dlmwrite(motOut, data, '-append', 'delimiter', '\t', 'precision', 6);
end
