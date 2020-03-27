function errorTable = calculateMarkerErrors(trcData, stoData)
% This functions compares two sets of marker data, such as original TRC
% data and the OpenSim-outputted kinematic fit data, and returns a new
% table containing the marker error for each marker at each frame. The two
% inputs can be tables, structs, or files. 
% errorTable = calculateMarkerErrors(trcData, stoData);

    trcData = Osim.interpret(trcData, 'TRC');
    stoData = Osim.interpret(stoData, 'TRC');
    % reorder tables to be in the same order
    startTime = max(trcData.Header(1), stoData.Header(1));
    endTime = min(trcData.Header(end), stoData.Header(end));
    labels = intersect(stoData.Properties.VariableNames, trcData.Properties.VariableNames, 'stable');
    
    %trcTable = Topics.cut(trcTable, startTime, endTime);
    %stoTable = Topics.cut(stoTable, startTime, endTime);    
    startIdx=find(trcData.Header==startTime,1);
    endIdx=find(trcData.Header==endTime,1);
    trcData=trcData(startIdx:endIdx,:);
    stoData=stoData(startIdx:endIdx,:);
    
    trcData = trcData(:, labels);
    stoData = stoData(:, labels);
    % subtract the two tables
    fullErrors = stoData{:, 2:end} - trcData{:, 2:end};
    % calculate the Euclidian distance and convert mm to m
    errorTable = array2table(sqrt(fullErrors(:, 1:3:end).^2 + fullErrors(:, 2:3:end).^2 + fullErrors(:, 3:3:end).^2)/1000);
    % set the variable names
    errorTable.Properties.VariableNames = cellfun(@(x) {strrep(x, '_x', '')}, labels(2:3:end));
    errorTable = [stoData(:, 1),  errorTable]; % include Header again
end
