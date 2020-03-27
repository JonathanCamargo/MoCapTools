function emgUnit = identifyEmg(signal1, signal2)
% Given an EMG signal and a GON signal, this function will return the index
% that is most likely to be the EMG signal. 

    signalLength = length(signal1);
    
    % Identify the signals using a Fourier transform. One signal is an EMG
    % signal, whereas the other is a goniometer.
    % Identification of signals:
        % Goniometer signal appears to be continuous and smooth
        % EMG signal is intermittent and displays abrupt patterns.

    Y = fft(signal1);
    n = abs(Y/signalLength);
    F1 = n(1:floor(signalLength/2)+1);
    F1Mean = mean(F1);
    F1ExceedMeanCount = length(find(F1 > F1Mean));

    Y = fft(signal2);
    n = abs(Y/signalLength);
    F2 = n(1:floor(signalLength/2)+1);
    F2Mean = mean(F2);
    F2ExceedMeanCount = length(find(F2 > F2Mean));

    if (F1ExceedMeanCount > F2ExceedMeanCount)
        emgUnit = 1;
    else
        emgUnit = 2;
    end
end
