function allMarkers = CleanLabels_LabelAroundGaps(allMarkers,varargin)
% allMarkers = CleanLabels_LabelAroundGaps(allMarkers,varargin)
% For a marker structure clean the marker labels by using the following steps:
%  1. Find the gaps in the data and determine the seed frames for
%  relabeling within the beggining and end of the longest gaps.
%  2. Attempt relabeling on those frames
% 
%  Options:
%       VerboseLevel  - (0) minimal output, 1 normal, 2 debug mode
%       MaxIterations - (2) Iterations of the clean labels algorithm

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('VerboseLevel',0, validScalar);
p.addParameter('MaxIterations',10,@isnumeric);
p.addParameter('MaxGaps',3,@isnumeric);
p.parse(varargin{:});
VerboseLevel = p.Results.VerboseLevel;

LABELINGMAXITERATIONS=p.Results.MaxIterations;
MAXGAPS=p.Results.MaxGaps;

if (VerboseLevel>0)
        fprintf('Finding the gaps...\n');
end

      
    for iters=1:LABELINGMAXITERATIONS
        % 2. Use relable to see if those new unlabled markers can be used
        change=false;
        
        fprintf('Labeling Iteration %d\n',iters);

        % For markers with the longest gaps check if it is possible to
        % relable at the start of the gap.
        [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
        gapTable=genGapTable(labeledMarkers);       
        if isempty(gapTable); change=false; break; end

        gapTable=sortrows(gapTable,'Length','descend');
        
        disp(head(gapTable));
        
        [~,loc]=unique(gapTable.Start,'stable');
        gapTable=gapTable(loc,:);
        %For the biggest gaps attempt to relable first
        biggestGaps=gapTable(gapTable.Length>mean(gapTable.Length),:);
        biggestGaps=biggestGaps(1:min([height(biggestGaps),MAXGAPS]),:);
        
        if size(biggestGaps,1)<size(gapTable)
           idx=size(biggestGaps,1)+1:size(gapTable);   
           extraN=min([MAXGAPS,numel(idx)]);
           biggestGaps=[biggestGaps;gapTable(randsample(idx,extraN),:)];
        end
        biggestGaps.headerLocsStart=cell(height(biggestGaps),1);
        biggestGaps.headerLocsEnd=cell(height(biggestGaps),1);
        for i=1:height(biggestGaps)
           section=Topics.cut(allMarkers,biggestGaps.Start(i)-1,biggestGaps.Start(i)+10);
           headerLocsStart=findHeadersWithUnlabeledMarkers(section,biggestGaps.Markers{i}); 
           section=Topics.cut(allMarkers,biggestGaps.End(i)-10,biggestGaps.End(i)+1);
           headerLocsEnd=findHeadersWithUnlabeledMarkers(section,biggestGaps.Markers{i});
           biggestGaps.headerLocsStart{i}=headerLocsStart;
           biggestGaps.headerLocsEnd{i}=headerLocsEnd;
        end

        % Relabel at headerlocsstart and header locsend
        biggestGaps.headerLocsStart=cellfun(@(x)(x(1:min([numel(x),5]))),biggestGaps.headerLocsStart,'Uni',0);
        biggestGaps.headerLocsEnd=cellfun(@(x)(x(1:min([numel(x),5]))),biggestGaps.headerLocsEnd,'Uni',0);
        
        s1=vertcat(biggestGaps.headerLocsStart{:});
        s2=vertcat(biggestGaps.headerLocsEnd{:});
        
        seeds=[s1;s2];
        for i=1:numel(seeds)
            fprintf('\tRelabeling @%d\n',seeds(i));
            [newMarkers,wasRelabeled]=Vicon.Relabel(allMarkers,seeds(i),'Verbose',VerboseLevel);
            if wasRelabeled
                allMarkers=newMarkers;
                change=true;
            end
        end

        if change==false
            fprintf('Could not find a markers by relabeling. There are still gaps, please label manually\n');
            break;
        end
    end
    
    fprintf('Report of gaps:\n');
    gapTable=genGapTable(labeledMarkers);       
    if isempty(gapTable)
        fprintf('No gaps found');
        return;
    end
    gapTable=sortrows(gapTable,'Length','descend');
    fprintf('Worst gaps:\n');
    head(gapTable)
end


function headerLocs=findHeadersWithUnlabeledMarkers(markers,referenceMarkerName)
% Find the frames that contain unlabeled markers that are in the vicinity of 
% the reference marker. Only when the referenceMarker is a nan.
% These is useful to create seeds for relabeling.

    [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
            ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(markers); 
    
    a.(referenceMarkerName)=markers.(referenceMarkerName); 
    origRefTbl=a.(referenceMarkerName); atbl=origRefTbl(~any(isnan(origRefTbl.Variables),2),:);
    a.(referenceMarkerName)=atbl;
    a=Topics.interpolate(a,markers.(referenceMarkerName).Header);
   
    a=struct2cell(a); refTbl=a{1};
    distanceToMarker=Topics.transform(@(x)vecnorm((x-refTbl{:,2:end}),2,2),unlabeledMarkers);
    
    if isempty(fieldnames(distanceToMarker))
        headerLocs=[];
        return;
    end
    
    distancetbl=Topics.consolidate(distanceToMarker,{},'Prepend',true);
    idx=sum(distancetbl{:,2:end}<200,2)>0;
    origIsNan=any(isnan(origRefTbl.Variables),2);
    idx=idx & origIsNan;
    headerLocs=distancetbl.Header(idx);            
end
