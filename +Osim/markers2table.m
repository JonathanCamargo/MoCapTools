function markerTable = markers2table(markerStruct)
% Parses a struct of marker data, such as one outputted by
% Vicon.ExtractMarkers and returns a table with the same information. The
% table will be in the same format as the output of TRC2table.
% 
% markerTable = markers2table(markerStruct)

    FS=200;
    assert(isstruct(markerStruct), 'Input must be a struct.');
    data = structfun(@(x) {x{:,2:end}}, markerStruct);
    data = [data{:}];
    
    markerNames=fieldnames(markerStruct);
    
    frame = markerStruct.(markerNames{1}).Header;
    time = (frame-1)/FS;
    data = [time, data];
    
    labels = fieldnames(markerStruct);
    labels = compose('%s_%c', string(labels), 'xyz')';
    labels = [{'Header'}, labels(:)'];    
    markerTable = array2table(data, 'VariableNames', labels);
end
