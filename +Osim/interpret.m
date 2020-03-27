function data = interpret(data, filetype, outputType)
% Osim.interpret will interpret an input variable data, which may be a path
% to an ascii file, a path to a mat file, a table, or a struct, and will
% return either a table, a path to an ascii file, or a struct, depending on
% outputType. filetype will select how the data should be interpreted,
% either as TRC, MOT, or STO. outputType can be 'table', 'struct', or
% 'file'. If outputType is not set, it will default to 'table'
% 
% data = Osim.interpret(data, filetype, outputType);
% 
% Examples: 
% trcFile = Osim.interpret(trcData, 'TRC', 'file');
% motTable = Osim.interpret(motData, 'MOT', 'table');
% trcStruct = Osim.interpret(trcData, 'TRC', 'struct');
% stoTable = Osim.interpret(stoData, 'STO');

    narginchk(2, 3);
    filetype = upper(filetype(filetype ~= '.'));
    assert(any(strcmp(filetype, {'TRC', 'MOT', 'STO'})), 'Filetype must be ''TRC'', ''MOT'', or ''STO''.');
    
    if ~exist('outputType', 'var')
        outputType = 'table';
    end
    outputType = lower(outputType);
    assert(any(strcmp(outputType, {'table', 'file', 'struct'})), 'OutputType must be ''table'', ''file'', or ''struct''.');

    %getFile = ~tableOnly;
    %getTable = tableOnly || (nargout == 2);
    write = eval(sprintf('@Osim.write%s', filetype));
    read = eval(sprintf('@Osim.read%s', filetype));
    if ischar(data) && ~exist(data, 'file')
        error('Data file could not be found.');
    end
    if isstruct(data)
        if strcmp(outputType, 'struct')
            return;
        end
        data = Osim.markers2table(data);
        if strcmp(outputType, 'table')
            return;
        end
        data = write(data);
    elseif istable(data)
        if strcmp(outputType, 'table')
            return;
        end
        if strcmp(outputType, 'struct')
            data = Osim.table2markers(data);
            return;
        end
        data = write(data);
    elseif endsWith(upper(data), ['.' filetype])
        if strcmp(outputType, 'file')
            file = [tempname() '.' filetype];
            % Create a temporary file copy of the file
            copyfile(data, file);
            data = file;
            return;
        end
        data = read(data);
        if strcmp(outputType, 'table')
            return;
        end
        data = Osim.table2markers(data);
    elseif endsWith(data, '.mat')
        data = load(data);
        vars = fieldnames(data);
        data = data.(vars{1});
        data = Osim.interpret(data, filetype, outputType);
    else
        error('Data could not be interpreted.');
    end
end
