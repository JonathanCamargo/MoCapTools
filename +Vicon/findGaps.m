function frames=findGaps(markers)
% For each marker in the markers struct, find the pair of frame index where the gap starts and ends
% remember that a gap is defined as a closed interval where data disapears and appears again (including 
% the frame before it disapeared and the frame after it appeared).
%
% frames=findGaps(markers)
% 
% markers is a structure with fields for each marker containing size=[N,3] N: number of frames, 3: x,y,z coordinates  
%
    
    markers = Osim.interpret(markers, 'TRC', 'struct');
	markerNames=fieldnames(markers);

	frames=markers;

	for i=1:length(markerNames)
		markerName=markerNames{i};
		markerData=markers.(markerName);      
        a=findNanIntervals(markerData{:,2});        
		frames.(markerName)=reshape(markerData.Header(a),[],2);
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
