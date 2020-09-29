function markerData = ExtractMarkers(c3dFile)
% ExtractMarkers returns a struct where the fieldnames are the markers
% and each field contains an nx3 array of point data for n frames. Any
% missing marker data is represented as NaN instead of with zeros.
% markerData = Vicon.ExtractMarkers(c3dFile)

    h = btkReadAcquisition(c3dFile);
    markerData = btkGetMarkers(h);
    firstFrame=btkGetFirstFrame(h);
    btkCloseAcquisition(h);
    markers = fieldnames(markerData); 
    
    for idx = 1:length(markers)
        marker = markers{idx};
        a=markerData.(marker);
        a(a==0)=nan;
        a=Vicon.transform(a, 'OsimXYZ');
        header=(firstFrame-1)+(1:size(a,1))';
        markerData.(marker) = array2table([header,a],'VariableNames',{'Header','x','y','z'});
    end
end
