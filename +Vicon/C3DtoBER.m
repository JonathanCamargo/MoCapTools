function ber = C3DtoBER(c3dFile)
% Returns BER data as a table from a C3D file. 
% ber = Vicon.C3DtoBER(c3dFile)

    if nargin < 1
        [filename, filepath] = uigetfile('*.c3d');
        if isequal(filename, 0)
            error('No C3D file selected.');
        end
        c3dFile = fullfile(filepath,filename);
    end
    c3dHandle = btkReadAcquisition(c3dFile);
    analogData = btkGetAnalogs(c3dHandle);
    ber = analogData.Electric_Potential_11;
    nRows = btkGetAnalogFrameNumber(c3dHandle);
    t0 = btkGetFirstFrame(c3dHandle);
    times = ((1:nRows) - 2 + t0)' / btkGetAnalogFrequency(c3dHandle);
    ber = [times, ber];
    ber = array2table(ber);
    ber.Properties.VariableNames = {'Header', 'BER'};
    btkCloseAcquisition(c3dHandle);
end
