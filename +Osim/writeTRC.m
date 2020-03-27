function trcFile = writeTRC(trcTable, varargin)
% Convert a table with marker data to a trc file.
% 
% trcFile = writeTRC(trcTable, varargin)
%
% trcTable : table with marker data (first column is frame or header)
% Returns trcFile: the path of the file generated
% 
% Description of optional inputs: 
% 
% FilePath: the file that the trc table should be written to. If this input
% is not provided, the data will be written to a random location in the
% temporary directory. 
% FilterFreq: The cutoff frequency that the data should be filtered at
% using a 4th order zero lag Butterworth filter. If FilterFreq is not
% provided, the data will be filtered at 6 Hz by default. If the data
% should not be filtered, FilterFreq should be set to a negative value. 

    narginchk(1, 5);
    trcTable = Osim.interpret(trcTable, 'TRC');
	
	p=inputParser;
	validScalar=@(x) isnumeric(x) && isscalar(x);
	addRequired(p,'trcTable',@istable);
    defaultFilePath=[tempname() '.trc'];	
    addParameter(p,'FilePath',defaultFilePath,@ischar);
	addParameter(p,'FilterFreq',6,validScalar);

	parse(p,trcTable,varargin{:});
    filterFreq=p.Results.FilterFreq;
    trcFile=p.Results.FilePath;
    
    if ~endsWith(trcFile, '.trc')
        trcFile = [trcFile '.trc'];
    end

    
    if ~(strcmp(trcTable.Properties.VariableNames(1),{'Header'}))
        error('Unrecognized table format');
    end
    if ~(mod(width(trcTable)-1,3)==0)
        error('Table can not be generated, number of channels in the table does not match with 3d coordinate system');
    end
    
    % Adapt the table to be Frame and time
	frames=array2table((0:1:length(trcTable.Header)-1)','VariableNames',{'Frame'});		        
	fullTable=[frames,trcTable];    
	fs = 1/mean(diff(trcTable.Header));
    
    data = fullTable.Variables;
    if filterFreq > 0
        data(:, 3:end) = Vicon.Filter(data(:, 3:end), filterFreq/(fs/2));
    end
           
	%For table columns use the names in the table, removing
	%the last two chars (_x,_y,_z)
    labels=trcTable.Properties.VariableNames(2:end);
    markerNames=strrep(labels(1:3:end), '_x', '');
    nMarkers=length(markerNames);
	
    text{1} = sprintf('PathFileType\t3\t(X/Y/Z)\t%s', trcFile);
	text{2} = strjoin({'DataRate','CameraRate','NumFrames','NumMarkers','Units','OrigDataRate','OrigDataStartFrame','OrigNumFrames'}, '\t');
    text{3} = sprintf('%4$d	%4$d	%1$d	%2$d	mm	%4$d	%3$d	%1$d	', size(data, 1), nMarkers, data(1, 1), fs);
    
    varNames = [{'Frame#','Time'},markerNames];
    text{4} = sprintf('%s\t', strjoin(varNames, '\t'));
    
    coordHeaders = compose('X%d\tY%d\tZ%d\t', repmat((1:nMarkers)',1, 3));
    
    text{5} = sprintf('\t\t%s', [coordHeaders{:}]);
    text = text';
    fh = fopen(trcFile, 'w');
    for i = 1:length(text)
        fprintf(fh, '%s\n', text{i});
    end
    fclose(fh);
    dlmwrite(trcFile, data, '-append', 'delimiter', '\t', 'precision', 8);
end
