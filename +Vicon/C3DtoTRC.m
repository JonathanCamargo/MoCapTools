function trc = C3DtoTRC(c3dFile)
% Exports TRC data from a C3D file and produce a table. Data is in OpenSim
% coordinate system.
% trcOutputFile = Vicon.C3DtoTRC(c3dFile)
% c3dFile is the file that data will be exported from. 

    narginchk(1,1);
    assert(ischar(c3dFile));
    
    c3dHandle = btkReadAcquisition(c3dFile);
    
    samplingFreq = btkGetPointFrequency(c3dHandle);
    frames = (btkGetFirstFrame(c3dHandle):btkGetLastFrame(c3dHandle))';
    meta = btkGetMetaData(c3dHandle);
    markerData = btkGetMarkersValues(c3dHandle);
    nPoints = btkGetPointNumber(c3dHandle);
    btkCloseAcquisition(c3dHandle);
    markerData(markerData == 0) = nan;
    markerData = Vicon.transform(markerData, 'OsimXYZ');
    
    labels = meta.children.POINT.children.LABELS.info.values;
	times = (frames-1)/samplingFreq;
	
    colNames = compose('%s_%c', string(labels), 'xyz')';
    colNames = colNames(:)';
	colNames = strrep(colNames, '.', '_');
    colNames = strrep(colNames, '*', 'C_');
    
  	trc=array2table([times,markerData],'VariableNames',[{'Header'},colNames]);
end
