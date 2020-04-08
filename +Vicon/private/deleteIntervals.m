function [markerData,deletedData] = deleteIntervals(markerData, intervals)
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
    markerData = Osim.interpret(markerData, 'TRC', 'struct');
    markerNames=fieldnames(intervals);
    for idx = 1:length(markerNames)
        markerName=markerNames{idx};
        if isempty(intervals.(markerName)); continue; end        
        thisMarkerData=Topics.select(markerData,markerName);
        deletedSegments=Topics.segment(thisMarkerData,intervals.(markerName),markerName);
        a=[deletedSegments{:}]; 
        deletedTable=vertcat(a.(markerName));
        deletedData=struct();
        deletedData.(markerName)=deletedTable;
        deleted=Topics.transform(@(x)(x*nan),deletedData,markerName);
        markerData=Topics.merge(markerData,deleted);
    end
end
