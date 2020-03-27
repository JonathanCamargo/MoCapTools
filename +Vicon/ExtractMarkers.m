function markerData = ExtractMarkers(c3dFile)
% ExtractMarkers returns a struct where the fieldnames are the markers
% and each field contains an nx3 array of point data for n frames. Any
% missing marker data is represented as NaN instead of with zeros.
% markerData = Vicon.ExtractMarkers(c3dFile)

    h = btkReadAcquisition(c3dFile);
    markerData = btkGetMarkers(h);
    btkCloseAcquisition(h);
    markers = fieldnames(markerData); 
    
    for idx = 1:length(markers)
        marker = markers{idx};
        a=markerData.(marker);
        a(a==0)=nan;
        markerData.(marker)=a;
        markerData.(marker) = Vicon.transform(markerData.(marker), 'OsimXYZ');
    end
end
