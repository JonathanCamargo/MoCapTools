function trc = C3DtoTRC(c3dFile,varargin)
% trcOutputFile = Vicon.C3DtoTRC(c3dFile)
% Exports TRC data from a C3D file and produce a table. 
% c3dFile is the file that data will be exported from. 
% By default data is in OpenSim coordinate system i.e. y-axis up, use
% second argument to specify the coordinates between 'OsimXYZ'(default) or 
% 'ViconXYZ'


    narginchk(1,2);
    assert(ischar(c3dFile));
    
    p=inputParser();
    p.addOptional('Transform','OsimXYZ',@(x)any(strcmp(x,{'OsimXYZ','ViconXYZ'})));
    p.parse(varargin{:});
    
    Transform=p.Results.Transform;
    c3dHandle = btkReadAcquisition(c3dFile);
    
    samplingFreq = btkGetPointFrequency(c3dHandle);
    frames = (btkGetFirstFrame(c3dHandle):btkGetLastFrame(c3dHandle))';
    meta = btkGetMetaData(c3dHandle);
    markerData = btkGetMarkersValues(c3dHandle);
    nPoints = btkGetPointNumber(c3dHandle);
    btkCloseAcquisition(c3dHandle);
    % markerData(markerData == 0) = nan; Force a marker to be a nan if it is exactly 0
    
    if strcmp(Transform,'OsimXYZ') %Transform to OpenSim coordinates 
        markerData = Vicon.transform(markerData, Transform);
    end
    
    labels = meta.children.POINT.children.LABELS.info.values;
	times = (frames-1)/samplingFreq;
	
    colNames = compose('%s_%c', string(labels), 'xyz')';
    colNames = colNames(:)';
	colNames = strrep(colNames, '.', '_');
    colNames = strrep(colNames, '*', 'C_');
    
  	trc=array2table([times,markerData],'VariableNames',[{'Header'},colNames]);
end
