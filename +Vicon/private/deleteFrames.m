function markerData = deleteFrames(markerData, markerNames, frames)
% This function deletes the specified markers from the data structure
% within the ranges given. 
% 
% markerData = deleteFrames(markerData, markers, frames);
% 
% markerData = a struct of marker data like one outputted by ExtractMarkers
% markers = 1 x n Cell array of cell arrays of the markers to update
% frames = 1 x n Cell array of indices to replace with NaN
% Ex. newData = deleteFrames(Vicon.ExtractMarkers('file.c3d'), {'L.ASIS', 'R.ASIS'}, {1:100, 1000:2000});
%     newData = deleteFrames(Vicon.ExtractMarkers('file.c3d'), 'L_Heel', [500:600 800:850]);

    if ~iscell(markerNames)
        markerNames = {markerNames};
    end
    if ~iscell(frames)
        frames = {frames};
    end
    markerNames = strrep(markerNames, '.', '_');
    for idx = 1:length(markerNames)
        marker = markerNames{idx};
        markerData.(marker){frames{idx}, :} = nan;
    end
end
