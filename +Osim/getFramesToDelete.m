function [markers, frames] = getFramesToDelete(errorTable, lowThresh, highThresh, FPFile)
% For a force plate data set and an error table for a single trial, return
% the markers that have high error in important regions of the trial, and
% the frames in which those errors occur.
% [markers, frames] = getFramesToDelete(errorTable, lowThresh, highThresh, FPFile)
% [markers, frames] = getFramesToDelete(errorTable, lowThresh, highThresh)
% errorTable should be a table of inverse kinematics marker errors outputted
% from Osim.IK. If FPFile is not provided, then it will be assumed that the
% entire trial is relevant. 

    % any region where the error exceeds lowThresh will be flagged as high,
    % but only those regions where the error ever exceeds highThresh will
    % actually be deleted. So if the error exceeds lowThresh but not
    % highThresh, nothing will happen in that region. If the error exceeds
    % both, then the entire region exceeding lowThresh will be marked for
    % deletion. 
    narginchk(1, 4);
    if ~exist('lowThresh', 'var')
        lowThresh = 0.04;
    end
    if ~exist('highThresh', 'var')
        highThresh = 0.06;
    end
    
    % Find the locations where the markers error as a structure containing
    % marker names as fieldnames and the frames where they have high erorrs
    % as the values.
    markerLocations = errorRange(errorTable, lowThresh, highThresh);
    
    if ~exist('FPFile', 'var')
        locations = true(1, height(errorTable));
    else
        % Find the locations where we care about as a logical vector.
        locations = identifyRegionsOfInterest(FPFile);
    end
    % if any part of a high error region falls within the locations we care
    % about, mark the entire region of error to be removed so that gaps
    % will be interpolated from good data. 
    markers = fieldnames(markerLocations)';
    for i = markers
        edges = conv(markerLocations.(i{:}), [1 -1]);
        edges = edges(1:end);
        risingEdges = find(edges == 1);
        fallingEdges = find(edges == -1) - 1;
        assert(numel(risingEdges) == numel(fallingEdges), 'Could not identify frames to delete.');
        for j = 1: length(risingEdges)
            if (any(locations(risingEdges(j):fallingEdges(j))))
                locations(risingEdges(j):fallingEdges(j)) = true;
            end
        end
    end
    
    % For each of the marker errors from the structure and the locations
    % where we care about within the trial, logical AND them together to
    % produce a logical vector.  This vector will be true only where there
    % are errors within the range where we care.
    % If there are no errors within the range where we care, remove the
    % marker from the list entirely.
    
    frames = structfun(@(mask) {find(mask & locations)}, markerLocations)';
    
    if ~iscell(frames)
        frames = {frames};
    end
    
    % remove frame 1 and the last frame as candidates for deletion so that
    % gaps can still be interpolated. 
    frames = cellfun(@(f) {setdiff(f, [1, height(errorTable)])}, frames);
    
    % remove elements with no frames for deletion 
    emptyMask = cellfun('isempty', frames);
    frames = frames(~emptyMask);
    markers = markers(~emptyMask);
end
