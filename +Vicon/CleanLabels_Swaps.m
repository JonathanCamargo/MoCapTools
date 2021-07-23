function allMarkers = CleanLabels_Swaps(allMarkers,varargin)
% allMarkers = CleanLabels_Swaps(allMarkers,varargin)
% For a labeled marker structure clean the marker labels by using the following steps:
% 1. Looking into possible marker swapping and unlabel the swapping events
% 2. Label around the swapping events
%  Options:
%       VerboseLevel  - (0) minimal output, 1 normal, 2 debug mode
%       MaxIterations - (2) Iterations of the clean labels algorithm

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);
p.parse(varargin{:});
Verbose = p.Results.Verbose;


% We start with a file that is labeled but potentially has problems
% Clean the labels by:

% 1. Looking into posible marker swapping and unlabel the swapping events
% 2. Label around the swapping events

Verbose=2;

markers=allMarkers;
%% 1. Looking into posible marker swapping and unlabel the swapping events
intervals=Vicon.findSwaps(markers);
gapIntervals=Vicon.findGaps(markers);
markers=Vicon.unlabelIntervals(markers,intervals); % discard the new unlabeled markers (bad data)
%% 2. Label around the swapping events

%Find The shortest section -before or after the interval-
swappedMarkerNames=fieldnames(intervals);
for markerIdx=1:numel(swappedMarkerNames)
    marker=swappedMarkerNames{markerIdx};
    gapIntervals=Vicon.findGaps(Topics.select(markers,marker));
    gapInterval=gapIntervals.(marker);
    for intervalIdx=1:numel(intervals.(marker))
        interval=intervals.(marker){intervalIdx};
        if VerboseLevel>0
            fprintf('Fixing swapped label for marker %s @%d-%d\n',marker,interval(1),interval(2));
        end
        %Determine the previous gap and the next gap from this interval
        previousGapIdx=find(gapInterval(:,2)<interval(1),1,'last');
        nextGapIdx=find(gapInterval(:,1)>interval(2),1,'first');
        if isempty(previousGapIdx) || isempty(nextGapIdx)
            continue;
        end
        %Check the distance to that gap
        previousGap=gapInterval(previousGapIdx,:); nextGap=gapInterval(nextGapIdx);
        [~,shortest]=min([interval(1)-previousGap(2) nextGap(1)-interval(2)]);

        % Now relabel. Where?
        % Find the next frame that has enough unlabeled markers in the vicinity
        % of the one that we just unlabeled.
        % Unlabel up to previousgap and relabel in the first nice frame after that
        
        toUnlabel=struct(marker,{{[previousGap(2) interval(1)]}});
        if VerboseLevel>0
            fprintf('\tUnlabeling for marker %s @%d-%d\n', marker,toUnlabel.(marker){:});
        end
        [tempMarkers,newUnlabeledMarkers]=Vicon.unlabelIntervals(markers,toUnlabel);        
        a=struct2cell(newUnlabeledMarkers);
        if isempty(a)
            continue;
        end
        utbl=a{1};
        tempMarkers=Topics.merge(tempMarkers,newUnlabeledMarkers);

        markerNames=Topics.topics(tempMarkers); unlabeledMarkerNames=markerNames(contains(markerNames,'C_'));
        umarkers=Topics.select(tempMarkers,unlabeledMarkerNames);
        distanceToMarker=Topics.transform(@(x)vecnorm((x-utbl{:,2:end}),2,2),umarkers);
        distancetbl=Topics.consolidate(distanceToMarker,{},'Prepend',true);
        idx=sum(distancetbl{:,2:end}<200,2)>1;
        headerLocs=distancetbl.Header(idx);            

        % Plot to check what unlabeled markers are close
        %{
        distancetbl2=distancetbl; distancetbl2.Header=distancetbl2.Header-20000;
        Topics.plot(struct('a',distancetbl2),'a','LineSpec',{'*'})
        %}
        for i=1:min([numel(headerLocs),5])
            headerloc=headerLocs(i);
            [tempMarkers,wasrelabeled]=Vicon.Relabel(tempMarkers,headerloc,'VerboseLevel',2);
            if wasrelabeled
                markers=tempMarkers;
            end
        end        

        % Unlabel up to nextgap and relabel in the first nice frame before that
        toUnlabel=struct(marker,{{[interval(2) nextGap(1)]}});
        if VerboseLevel>0
            fprintf('\tUnlabeling for marker %s @%d-%d\n', marker,toUnlabel.(marker){:});
        end
        [tempMarkers,newUnlabeledMarkers]=Vicon.unlabelIntervals(markers,toUnlabel);
        a=struct2cell(newUnlabeledMarkers); utbl=a{1};
        tempMarkers=Topics.merge(tempMarkers,newUnlabeledMarkers);

        markerNames=Topics.topics(tempMarkers); unlabeledMarkerNames=markerNames(contains(markerNames,'C_'));
        umarkers=Topics.select(tempMarkers,unlabeledMarkerNames);
        distanceToMarker=Topics.transform(@(x)vecnorm((x-utbl{:,2:end}),2,2),umarkers);
        distancetbl=Topics.consolidate(distanceToMarker,{},'Prepend',true);

        idx=sum(distancetbl{:,2:end}<200,2)>1;
        headerLocs=distancetbl.Header(idx);            

        % Plot to check what unlabeled markers are close
        %{
        distancetbl2=distancetbl; distancetbl2.Header=distancetbl2.Header-20000;
        Topics.plot(struct('a',distancetbl2),'a','LineSpec',{'*'})
        %}     

        for i=1:min([numel(headerLocs),5])
            headerloc=headerLocs(i);
            [tempMarkers,wasrelabeled]=Vicon.Relabel(tempMarkers,headerloc,'VerboseLevel',2);                
            if wasrelabeled
                markers=tempMarkers;
            end
        end
     
    end

allMarkers=markers;
end


