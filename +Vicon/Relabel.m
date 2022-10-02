function [relabeledMarkers,wasRelabeled]=Relabel(allMarkers,headerloc,varargin)
% Relabel a set of markers at a given header value
%  [relabeledMarkers,wasRelabeled]=Relabel(allMarkers,headerloc,varargin)
%
%       VerboseLevel  - (0) minimal output, 1 normal, 2 debug mode
%       MaxDistance   - (30) mm  maximum distance to accept linking
%
% 
validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('VerboseLevel',0, validScalar);
p.addParameter('MaxDistance',30, validScalar);
p.addParameter('Method','trajectory');
p.addParameter('OsimFile',{});
p.addParameter('VskFile',{});

p.parse(varargin{:});
VerboseLevel = p.Results.VerboseLevel;
MaxDistance = p.Results.MaxDistance;

wasRelabeled=false; % Return if this made any changes in labels

%% Extract names for convenience
[allMarkerNames,unlabeledMarkers,unlabeledMarkerNames,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
headers=allMarkers.(allMarkerNames{1}).Header;
%% For efficiency cut the allMarkers to a small section around headerloc for convenience
if (headers(end)-headers(1))>200
    section=Topics.cut(allMarkers,headerloc-100,headerloc+100);
else
    section=allMarkers;
end
headers=section.(allMarkerNames{1}).Header;
headerIdx=find(headers==headerloc,1);

if numel(unlabeledMarkerNames)==0 
    relabeledMarkers=allMarkers;
    wasRelabeled=false;
    return;
end


%% For efficiency only work with lmarkers that are not labeled at this frame and
% umarkers that exist at this frame.
% it would be better to just check the labeled points that have
% gaps here.
thisFrame=Topics.cut(section,headerloc,headerloc,allMarkerNames);
hasNaN=Topics.processTopics(@(x)any(isnan(x.Variables),2),thisFrame,allMarkerNames);
hasNaN=struct2array(hasNaN);
[~,ind]=ismember(labeledMarkerNames,allMarkerNames);
% Get all the points from missing labeled markers    
isMissing=hasNaN(ind);
lnames=labeledMarkerNames(isMissing);
if isempty(lnames)
    if (VerboseLevel>0)
        fprintf('No missing markers in frame header=%f\n',headerloc);
    end
    relabeledMarkers=allMarkers;
    wasRelabeled=false;
    return;
end
m=Topics.select(section,lnames);
predicted=predictPosition(m,headerloc);
a=struct2cell(predicted); a=vertcat(a{:});
lpoints=a(:,2:end);       

% Get all the points from existing unlabeled markers
[~,ind]=ismember(unlabeledMarkerNames,allMarkerNames);
isMissing=hasNaN(ind);
unames=unlabeledMarkerNames(~isMissing);
if isempty(unames)
    if (VerboseLevel>0)
        fprintf('No unlabeled markers in frame header=%1.2f\n',headerloc);
    end
    relabeledMarkers=allMarkers;
    wasRelabeled=false;
    return;
end
m=Topics.select(thisFrame,unames);
a=struct2cell(m); a=vertcat(a{:});
upoints=a(:,2:end);       

%% Check linking matches between markers
[ target_indices, target_distances, unassigned_targets, total_cost ] = hungarianlinker(lpoints.Variables,upoints.Variables, MaxDistance);
% Expand target_indices to all the labeledMarkerNames
target_indices_tmp=-ones(1,numel(labeledMarkerNames));
[~,locInd]=ismember(lnames,labeledMarkerNames);
for target_indicesIdx=1:numel(target_indices)
   target_indices_tmp(locInd(target_indicesIdx))=target_indices(target_indicesIdx);
end
target_indices=target_indices_tmp;

%% Now use target_indices to relabel

 % Each unlabeled point that has a target index
for i=1:height(upoints)
   % Check if this has a target index
   lmarkerIdx=find(target_indices==i,1);
   if ~isempty(lmarkerIdx)
       if (VerboseLevel==2)
            fprintf('%s->%s @%1.2f\n',unames{i},labeledMarkerNames{lmarkerIdx},headerloc);
       end
       %This means that the ith upoint in reality corresponds to labeledMarkerNames{i}
       %So, lets grab the data from the last gap up to the next gap of the upoint.
       udata=unlabeledMarkers.(unames{i});
       % Find previous gap and next gap of udata       
       a=isnan(udata{:,2:end});
       hasAll=~any(a,2);
       mask=udata.Header<headerloc;
       previousGapIdx=find(((~hasAll) & mask),1,'last');
       nextGapIdx=find(((~hasAll) & ~mask),1,'first');
       if isempty(nextGapIdx); nextGapIdx=numel(hasAll)+1; end
       if isempty(previousGapIdx); previousGapIdx=0; end

       ustart=udata.Header(previousGapIdx+1);
       uend=udata.Header(nextGapIdx-1);       
       a=Topics.cut(unlabeledMarkers,ustart,uend,unames(i));
       utable=a.(unames{i});
       % Insert the unlabeled data into the labeled marker
       z=labeledMarkers.(labeledMarkerNames{lmarkerIdx});
       z{previousGapIdx+1:nextGapIdx-1,:}=utable.Variables;
       labeledMarkers.(labeledMarkerNames{lmarkerIdx})=z; 
       % Remove the unlabeled data from the unlabeled marker
       utable{:,2:end}=nan*utable{:,2:end};
       z=unlabeledMarkers.(unames{i});
       z{previousGapIdx+1:nextGapIdx-1,:}=utable.Variables;
       unlabeledMarkers.(unames{i})=z;
       wasRelabeled=true;
   end
end

% relabeledMarkers=Topics.merge(unlabeledMarkers,labeledMarkers);
relabeledMarkers=Topics.merge(allMarkers,labeledMarkers);
newmarkers=setdiff(fieldnames(unlabeledMarkers),fieldnames(relabeledMarkers));
for i=1:numel(newmarkers)
    relabeledMarkers.(newmarkers{i})=relabeledMarkers.(allMarkerNames{1});
    relabeledMarkers.(newmarkers{i}){:,2:end}=nan;
end
relabeledMarkers=Topics.merge(relabeledMarkers,unlabeledMarkers);



end


%% %%%%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smoothedTable=smoothTable(tableData)
    N=ceil(height(tableData)/10);   
    a=[smooth(tableData.x,N),smooth(tableData.y,N),smooth(tableData.z,N)];
    varNames=tableData.Properties.VariableNames;
    smoothedTable=array2table([tableData.Header a],'VariableNames',{'Header',varNames{2:end}});
end

function markers=predictPosition(markers,i)
    % For a marker set determine the position of the markers at a given
    % time.
    allmarkers=fieldnames(markers);
    %Smooth first to make it better   
    markers=Topics.processTopics(@smoothTable,markers,allmarkers);
    markers=Topics.interpolate(markers,i,allmarkers);
end


function outMarkers=predictPositionModelBased(markers,frame,segmentMarkers)
    % For a marker set determine the position of the markers at a given
    % time, using the segmentMarkers information.
        
    allmarkers=fieldnames(markers);
    %Smooth first to make it better   
    outMarkers=Topics.processTopics(@smoothTable,markers,allmarkers);
    outMarkers=Topics.interpolate(outMarkers,frame,allmarkers); %This is the predicted position based on prior indiviual marker trajectories 
    % Also comute the predicted position based on other markers on the same
    % segment. Use rigidBodyFill or patternFill depending on number of
    % markers.
    
    % find markers that have most gaps which means are more probable that
    % individual trajectory traking fails.
    countnans_fun=@(x)(sum(isnan(x.Variables),'all')/3);
    nanCount=Topics.processTopics(countnans_fun,markers,allmarkers);
    a=struct2array(nanCount);
    [sorted_nanCounts,idx]=sort(a,'descend');
    sorted_allmarkers=allmarkers(idx);
    isOverThreshold=(sorted_nanCounts>mean(sorted_nanCounts(sorted_nanCounts~=0)));
    correctedMarkers=sorted_allmarkers(isOverThreshold);
    
    for i=1:numel(correctedMarkers)
        correctedMarker=correctedMarkers{i};
        possibleDonors=segmentMarkers.(segmentMarkers.(correctedMarker));
        markerData=markers.(correctedMarker);
        hasData=~any(isnan(markerData.Variables),2);
        framesWithCorrectedMarker=markerData.Header(hasData);
        previousFramesWithCorrectedMarker=framesWithCorrectedMarker(framesWithCorrectedMarker<frame);
        frameWithCorrectedMarker=previousFramesWithCorrectedMarker(end);                
        if numel(possibleDonors)>2
            donors=setdiff(possibleDonors,correctedMarker);                                                 
            corrected=Vicon.RigidBodyFill(markers,correctedMarker,donors,frameWithCorrectedMarker,frame+1,'FW',true);            
            outMarkers.(correctedMarker)=corrected.(correctedMarker);                               
        end
        if numel(possibleDonors)<2
            donors=setdiff(possibleDonors,correctedMarker);                     
            corrected=Vicon.PatternFill(markers,correctedMarker,donors,frameWithCorrectedMarker,frame+1,FW);                        
            outMarkers.(correctedMarker)=corrected.(correctedMarker);
        end
    end            
    outMarkers=Topics.cut(outMarkers,frame,frame,allmarkers);
end




