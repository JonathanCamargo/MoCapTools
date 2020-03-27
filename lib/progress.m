function h = progress(x, h)
% Modified version of MATLAB's waitbar() that gives rough time estimations.
% Syntax is similar to waitbar(). progress() should be called with the
% second input to automatically estimate remaining time. 
% h = progress(x)
% h = progress(x, h)
% h is a handle to a figure showing a progress bar. 
% x is the fraction length of the waitbar, between 0 and 1.
%
% Example:
% h = progress(0);
% for i = 1:n
%   % do some code
%   progress(i/n, h);
% end
% delete(h);

    narginchk(1, 2);
    persistent ticSeed;
    persistent totalTimeEst;
    if ~exist('h', 'var')
        ticSeed = tic();
        totalTimeEst = 0;
        h = waitbar(x);
    end
    elapsedTime = toc(ticSeed);
    totalTimeCurEst = elapsedTime/x;
    if totalTimeEst == 0 || ~isfinite(totalTimeEst)
        totalTimeEst = totalTimeCurEst;
    else
        % exponentially weighted moving average of estimated total time
        totalTimeEst = 0.5*totalTimeCurEst + 0.5*totalTimeEst;
    end
    timeRemaining = totalTimeEst - elapsedTime;
    if isfinite(timeRemaining)
        timeString = sprintf('Estimated time remaining: %.f seconds', timeRemaining);
        if timeRemaining > 60
            timeString = sprintf('%s (%.1f minutes', timeString, timeRemaining/60);
            if timeRemaining > 3600
                timeString = sprintf('%s, or %.1f hours)', timeString, timeRemaining/3600);
            else
                timeString = sprintf('%s)', timeString);
            end
        end
        timeString = [timeString '.'];
    else
        timeString = 'Estimated time remaining: Unknown.';
    end
    waitbar(x, h, timeString);
end
