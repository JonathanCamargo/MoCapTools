function frames=findGaps(markerData)
% For each marker in the marker data, find the pair of frame indices where
% the gap starts and ends. A gap is defined as a closed interval where data
% disapears and appears again, including the frame before it disapeared and
% the frame after it appeared. This means that missing data until the end
% of the capture and missing data at the beginning of a capture are not
% counted as gaps, as they do not have data on both sides of the gap.
%
% frames=findGaps(markerData)
% markerData can be a struct, table, trc file, or mat file containing
% marker data.

    markerData = Osim.interpret(markerData, 'TRC', 'struct');
	markerNames=fieldnames(markerData);

	frames=markerData;

	for i=1:length(markerNames)
		markerName=markerNames{i};
		thisMarkerData=markerData.(markerName);
		frames.(markerName)=findNanIntervals(thisMarkerData(:,1));
	end
end

% Example:
% x=[1 2 3 4 nan nan nan nan 3 4]';
% markers.a=x;


%%%%%%%%%%%%%%%%%%%%%%
%% Helper functions %%
%%%%%%%%%%%%%%%%%%%%%%

function intervals=findNanIntervals(x)
% For a vector x find the intervals from right before a NaN shows up to right before it
% disappears.
%
% intervals=findNanIntervals(x)
% 
% x is the vector (containing NaN values here and there)
% intervals is an N,2 array containing indices for where the nan intervals occur.

    a=isnan(x);
    gaps = cellfun(@(c) {[c(1)-1; c(end)+1]}, splitLogical(a));
    if isempty(gaps)
        intervals = zeros(0, 2);
        return;
    end
    if (a(1)==true)
        %Marker started with missing values
        gaps = gaps(2:end);
    end
    if (a(end)==true)
        %Marker ended with missing values
        gaps = gaps(1:end-1);
    end
    intervals = [gaps{:}]';
end
