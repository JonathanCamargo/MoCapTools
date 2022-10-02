function data = gen2table(file)
%% function to take a generalized vicon output file and convert it to a table

    try
        restrictedChars = [' ', ':', '#', '.']; %chars to remove from header names
        data = importdata(file, ',', 5);
        text = data.textdata;
        data = data.data;

        devices = text{3,1};
        channels = text{4,1};%hardcoded
        for currChar = restrictedChars
            devices(devices == currChar) = [];
            channels(channels == currChar) = [];
        end
        devices(devices == '-') = '_';
        devices = strsplit(devices, ',', 'CollapseDelimiters', false);
        channels = strsplit(channels, ',', 'CollapseDelimiters', false);

        devices_dict = devices(~strcmp(devices, ''));
        devices_inds = 1:length(devices);
        for devInd = 1:length(devices_dict)
            currDevice = devices_dict{devInd};
            deviceChannels = devices_inds(strcmp(devices, currDevice)):devices_inds(strcmp(devices, currDevice)) + 2;
            for ind = deviceChannels
                channels{ind} = [currDevice, '_',  channels{ind}];
            end
        end

        data = array2table(data);
        data.Properties.VariableNames = channels;
    catch ME
        data = [];
        fprintf('Error generating table for %s\n', file);
        fprintf('%s\n\n', getReport(ME, 'extended'));
    end
end