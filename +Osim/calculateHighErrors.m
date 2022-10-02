function highErrorTable = calculateHighErrors(errorTable, threshold)
% calculateHighErrors determines where the inverse kinematics error listed
% in errorTable exceeds the value given in threshold, and what markers are
% causing that error. The information is returned in a table
% highErrorTable. The default value of threshold is 0.06. errorTable can be
% the second output from Osim.IK.
    
    narginchk(1, 2);
    if ~exist('threshold', 'var')
        threshold = 0.06;
    end
    %% Determine regions of high error
    markers = errorTable.Properties.VariableNames(2:end);
    highErrorTable = table;
    for markerIdx = 1:length(markers)
        marker = markers{markerIdx};
        errorMask = [false; errorTable.(marker) > threshold; false];
        if ~any(errorMask)
            continue;
        end
        errorStartIdxs = find(diff(errorMask) == 1);
        errorEndIdxs = find(diff(errorMask) == -1) - 1;
        assert(length(errorStartIdxs) == length(errorEndIdxs), 'Could not identify regions of high error.');
        % initialize table
        markerErrorInfo = table;
        markerErrorInfo.StartTime = errorTable.Header(errorStartIdxs);
        markerErrorInfo.EndTime = errorTable.Header(errorEndIdxs);
        markerErrorInfo.StartFrame = errorStartIdxs;
        markerErrorInfo.EndFrame = errorEndIdxs;

        %initialize values
        markerErrorInfo.Marker = repmat({[]}, height(markerErrorInfo), 1);
        markerErrorInfo.AvgError = zeros(height(markerErrorInfo), 1);
        for i = 1:length(errorStartIdxs)
            markerErrorInfo.Marker(i) = {marker};
            markerErrorInfo.AvgError(i) = mean(errorTable.(marker)(errorStartIdxs(i):errorEndIdxs(i)));
            markerErrorInfo.PeakError(i) = max(errorTable.(marker)(errorStartIdxs(i):errorEndIdxs(i)));
        end
        highErrorTable = [highErrorTable; markerErrorInfo];
    end
    if ~isempty(highErrorTable)
        highErrorTable = sortrows(highErrorTable, 'AvgError', 'descend');
    end
end
