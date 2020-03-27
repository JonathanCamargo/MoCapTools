function sync = C3DtoSYNC(c3dFile)
% Returns SYNC data as a table from a C3D file. 
% sync = Vicon.C3DtoSYNC(c3dFile)

    if nargin < 1
        [filename, filepath] = uigetfile('*.c3d');
        if isequal(filename, 0)
            error('No C3D file selected.');
        end
        c3dFile = fullfile(filepath,filename);
    end
    c3dHandle = btkReadAcquisition(c3dFile);
    analogData = btkGetAnalogs(c3dHandle);
    sync = analogData.Electric_Potential_1;
    nRows = btkGetAnalogFrameNumber(c3dHandle);
    t0 = btkGetFirstFrame(c3dHandle);
    times = ((1:nRows) - 2 + t0)' / btkGetAnalogFrequency(c3dHandle);
    sync = [times, sync];
    sync = array2table(sync);
    sync.Properties.VariableNames = {'Header', 'SYNC_IN'};
    btkCloseAcquisition(c3dHandle);
end
