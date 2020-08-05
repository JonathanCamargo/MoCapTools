function markerStruct = table2markers(markerTable)
% Parses a table of marker data, such as one outputted by TRC2table and
% returns a struct with the same information. The struct will be in the
% same format as the output of Vicon.ExtractMarkers.
% 
% markerStruct = table2markers(markerTable)

    FS=200;
    assert(istable(markerTable), 'Input must be a table.');
    data = markerTable.Variables;
    labels = markerTable.Properties.VariableNames;
    if strcmpi(labels{1}, 'header')
        data = data(:, 2:end);
        labels = labels(2:end);
    end
    if strcmpi(labels{1}, 'frame')
        data = data(:, 2:end);
        labels = labels(2:end);
    end
    if strcmpi(labels{1}, 'time')
        data = data(:, 2:end);
        labels = labels(2:end);
    end
    nMarkers = length(labels)/3;
    if floor(nMarkers)~=nMarkers
		error('Table can not be generated, number of channels in the table does not match with 3d coordinate system');
    end
    markerStruct = struct();
    for idx = 1:3:size(data, 2)
        markerStruct.(strrep(labels{idx}, '_x', '')) = array2table([round(markerTable.Header*FS+1) data(:, idx:idx+2)],'VariableNames',{'Header','x','y','z'});
    end
end
