function newSignal = Filter(signal, f0)
% Vicon.Filter filters a signal in the same manner that Vicon does, with a
% 4th order, zero lag, butterworth filter. The cutoff frequency should be
% supplied in radians per sample of the signal, divided by pi, in the same
% manner as the MATLAB function butter(). This can be calculated as
% (cutoff frequency)/(sampling frequency / 2).
% 
% [newSignal] = Vicon.Filter(signal, cutoffFrequency)
% Vicon.Filter will filter each column of signal independently.

% Details taken from: 
% https://docs.vicon.com/display/Nexus25/Pipeline+tools
% in the section "Fill Gap & Filter Data operations" for the operation
% "Filter Analog Data - Butterworth"

% The filter works by applying a 2nd order filter twice, once forwards, and
% once in reverse, to cancel out any phase shift introduced, using the
% MATLAB function filtfilt(). The cut-off frequency of the designed filter
% must be adjusted so that the overall attenuation at the cut-off frequency
% is -3 dB. 

    %stop script if signal is less than 6 frames long
    if size(signal, 1) <= 6
        newSignal = signal;
        return
    end

    % this number being multiplied by the cut-off frequency was calculated
    % to produce an overall attenuation of -3 dB (or 20*log10(1/sqrt(2)))
    % at the intended cutoff frequency when the filter is applied twice
    k = (sqrt(2)-1)^-0.25;
    [b, a] = butter(2, k * f0);
        
    % Deal with nan values by splitting the signal into parts where there
    % are no nan values, filtering them separately, and putting them back
    % together. 
    edges = arrayfun(@(c) conv(~isnan(signal(:, c)), [1,-1]), 1:size(signal, 2), 'UniformOutput', false);
    edges = [edges{:}];

    [risings, cols] = find(edges == 1);
    [fallings, ~] = find(edges == -1);
    assert(length(risings) == length(fallings), 'Could not identify NaN regions.');

    goodRows = arrayfun(@(u, v){u:v-1}, risings, fallings);

    newSignal = nan(size(signal));
    for idx = 1:length(goodRows)
        sigPart = signal(goodRows{idx}, cols(idx));
        if length(sigPart) <= 6 % filtfilt cannot filter signals less than 6 samples long
            newSignal(goodRows{idx}, cols(idx)) = sigPart;
        else
            newSignal(goodRows{idx}, cols(idx)) = filtfilt(b, a, sigPart);
        end
    end
    reshape(newSignal, size(signal));
end
