function markerLocations = errorRange(errorTable, lowThresh, highThresh)
% This function receives the high error table from calculateHighErrors.m
% and the number of frames that exist within the trial, and outputs a
% struct containing the markers as field names and logical vectors as the
% values. The logical vector is true within the indices corresponding to
% the frames when high errors exist. Only regions of error where the error
% ever exceeds threshold will be marked true. 

% markerLocations = errorRange(errorTable, lowThresh, highThresh)

    nFrames = height(errorTable);
    highErrorTable = Osim.calculateHighErrors(errorTable, lowThresh);
    markerLocations = struct();
    for i = 1:height(highErrorTable)
        if highErrorTable.PeakError(i) < highThresh
            continue;
        end
        badMarker = strrep(highErrorTable.Marker{i}, '.', '_'); % Replace the periods within the function with underscores.  This allows them to be used as struct fieldnames.
        if ~any(contains(fieldnames(markerLocations), badMarker))
            markerLocations.(badMarker) = false(1, nFrames);
        end
        startFrame = max(highErrorTable.StartFrame(i), 1); 
        endFrame = min(highErrorTable.EndFrame(i), nFrames);
        markerLocations.(badMarker)(startFrame:endFrame) = true;        
    end
    
    % Set each of the logical vectors within the struct to the same length.
    errorMarkers = fieldnames(markerLocations);
    for i = 1:length(errorMarkers)
        markerLocations.(errorMarkers{i})(length(markerLocations.(errorMarkers{i})) + 1 : nFrames) = false;
    end
end
