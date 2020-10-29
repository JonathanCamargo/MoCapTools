function [emg, gon] = C3DtoBIO(c3dFile)
% Returns EMG and GON data as tables from a C3D file. 
% [emg, gon] = Vicon.C3DtoBIO(c3dFile)

    if nargin < 1
        [filename, filepath] = uigetfile('*.c3d');
        if isequal(filename, 0)
            error('No C3D file selected.');
        end
        c3dFile = fullfile(filepath,filename);
    end
    c3dHandle = btkReadAcquisition(c3dFile);
    analogData = btkGetAnalogs(c3dHandle);
    biom1 = analogData.Voltage_1;
    biom2 = analogData.Voltage_11;
    emgIdx = identifyEmg(biom1, biom2);
    channels = fieldnames(analogData);
    biom1Idx = find(strcmp(channels, 'Voltage_1'));
    biom1Idx = biom1Idx:(biom1Idx+7);
    biom2Idx = find(strcmp(channels, 'Voltage_11'));
    biom2Idx = biom2Idx:(biom2Idx+7);
    nRows = btkGetAnalogFrameNumber(c3dHandle);
    % Assume that frist frame (usually frame1) is equivalent to time t=0
    t0 = (btkGetFirstFrame(c3dHandle)-1)/btkGetPointFrequency(c3dHandle);    
    times = t0+(((1:nRows) - 1 )' / btkGetAnalogFrequency(c3dHandle));
    times = array2table(times);
    times.Properties.VariableNames = {'Header'};
    
    warning('Biometrics channels are hardcoded for SF2018 experiment')
    
    gonIDs = {'GON', 'EMG', 'EMG', 'EMG', 'GON', 'GON', 'EMG', 'EMG'};
    emgIDs = {'EMG', 'EMG', 'EMG', 'GON', 'GON', 'EMG', 'EMG', 'EMG'};
    ids = [emgIDs, gonIDs];
    gonHeads = {'knee_sagittal', 'bicepsfemoris', 'semitendinosus', 'gracilis', 'hip_sagittal', 'hip_frontal', 'gluteusmedius', 'rightexternaloblique'};
    emgHeads = {'gastrocmed', 'tibialisanterior', 'soleus', 'ankle_sagittal', 'ankle_frontal', 'vastusmedialis', 'vastuslateralis', 'rectusfemoris'};
    labels = [emgHeads, gonHeads];
    tab = struct2table(analogData);
    if emgIdx == 1
        biometrics = tab(:, biom1Idx);
        biometrics = [biometrics, tab(:, biom2Idx)];
    else
        biometrics = tab(:, biom2Idx);
        biometrics = [biometrics, tab(:, biom1Idx)];
    end
    biometrics.Properties.VariableNames = labels;
    emg = [times, biometrics(:, contains(ids, 'EMG'))];
    gon = [times, biometrics(:, contains(ids, 'GON'))];
    btkCloseAcquisition(c3dHandle);
end
