function c3dFileOut = TRCtoC3D(markerTable, c3dFileOrig, c3dFileOut)
% c3dFileOut = TRCtoC3D(markerTable, c3dFileOrig, c3dFileOut)
% Writes a table of marker data, such as one taken from Osim.readTRC, and
% writes it to a new C3D file, using an old C3D file as a reference for any
% required metadata. c3dFileOrig will not be modified, and a new C3D file
% will be written to c3dFileOut, if it is provided. 

    if ~exist('c3dFileOut', 'var')
        c3dFileOut = [tempname() '.c3d'];
    end
    if ~exist('c3dFileOrig', 'var')
        error('You must provide the original C3D file that the marker data was taken from.');
    end
    if ~exist(c3dFileOrig, 'file')
        error('Original C3D file not found.');
    end
    if ~endsWith(c3dFileOut, '.c3d')
        c3dFileOut = [c3dFileOut '.c3d'];
    end
    markerTable = Osim.interpret(markerTable, 'TRC');
    
    header=markerTable.Header;   
    c3dHandle = btkReadAcquisition(c3dFileOrig);
    
    if any(~isinteger(diff(header)))
        dT=mean(diff(header));
        sectionFrames=round(header/dT)+1;
        % header is time     
        % originalFrames = (btkGetFirstFrame(c3dHandle):btkGetLastFrame(c3dHandle))';
        btkSetFirstFrame(c3dHandle,sectionFrames(1));
        btkSetFrameNumber(c3dHandle,sectionFrames(end)-sectionFrames(1)+1);                                        
    end
    
    
    
    data = markerTable{:, 2:end};
    data = Vicon.transform(data, 'ViconXYZ');
    labels = markerTable.Properties.VariableNames;
    labels = labels(2:3:end);
    labels = strrep(labels, '_x', '');
    labels = strrep(labels, 'C_', '*');
    btkSetPointNumber(c3dHandle, length(labels))
    info=btkMetaDataInfo('Char',labels);

    btkSetMetaData(c3dHandle, 'POINT', 'LABELS', info);
    for i=1:numel(labels)
        btkSetPointLabel(c3dHandle,i,labels{i});
    end    
    btkSetMarkersValues(c3dHandle, data);
    residuals = -isnan(data(:, 1:3:end));
    btkSetMarkersResiduals(c3dHandle, residuals);
    btkWriteAcquisition(c3dHandle, c3dFileOut);
    btkCloseAcquisition(c3dHandle);
end
