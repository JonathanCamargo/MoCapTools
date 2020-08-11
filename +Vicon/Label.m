function [relabeledMarkers,wasChanged]=Label(allMarkers,frameloc,varargin)
% Relabel a set of markers at a given header value. This function finds
% unlabeled markers and markers and assign them a label from the labels
% that are not used at the frame <frameloc>. Returns the new markerData
% and a boolean that informs if there was any change applied.
% 
%  [allMarkers,wasChanged]=Relabel(allMarkers,frameloc,varargin)
%
%
%       Verbose  - (0) minimal output, 1 normal, 2 debug mode
%       MaxDistance   - (30) mm  maximum distance to accept linking
%
% 
validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);
p.addParameter('MaxDistance',30, validScalar);

p.parse(varargin{:});
Verbose = p.Results.Verbose;
MaxDistance = p.Results.MaxDistance;

wasChanged=false; % Return if this made any changes in labels

%% Extract names for convenience
[allMarkerNames,unlabeledMarkers,unlabeledMarkerNames,labeledMarkers,labeledMarkerNames] = Vicon.MarkerCategories(allMarkers);
headers=allMarkers.(allMarkerNames{1}).Header;

%% For efficiency cut the allMarkers data to a small section around frameloc
if (headers(end)-headers(1))>200
    section=Topics.cut(allMarkers,frameloc-100,frameloc+100);
else
    section=allMarkers;
end
headers=section.(allMarkerNames{1}).Header;
headerIdx=find(headers==frameloc,1);

if numel(unlabeledMarkerNames)==0 
    relabeledMarkers=allMarkers;
    wasChanged=false;
    return;
end


%% For efficiency only work with lmarkers that are not labeled at this frame and
% umarkers that exist at this frame.
% it would be better to just check the labeled points that have
% gaps here.
thisFrame=Topics.cut(section,frameloc,frameloc,allMarkerNames);
hasNaN=Topics.processTopics(@(x)any(isnan(x.Variables),2),thisFrame,allMarkerNames);
hasNaN=struct2array(hasNaN);
[~,ind]=ismember(labeledMarkerNames,allMarkerNames);
% Get all the points from missing labeled markers    
isMissing=hasNaN(ind);
lnames=labeledMarkerNames(isMissing);
if isempty(lnames)
    if (Verbose>0)
        fprintf('No missing markers in frame header=%f\n',frameloc);
    end
    relabeledMarkers=allMarkers;
    wasChanged=false;
    return;
end
m=Topics.select(section,lnames);
predicted=predictPosition(m,frameloc);
a=struct2cell(predicted); a=vertcat(a{:});
lpoints=a(:,2:end); 
lpoints=lpoints(~any(isnan(lpoints.Variables),2),:);
lnames=lnames(~any(isnan(lpoints.Variables),2),:);

% Get all the points from existing unlabeled markers
[~,ind]=ismember(unlabeledMarkerNames,allMarkerNames);
isMissing=hasNaN(ind);
unames=unlabeledMarkerNames(~isMissing);
if isempty(unames)
    if (Verbose>0)
        fprintf('No unlabeled markers in frame header=%1.2f\n',frameloc);
    end
    relabeledMarkers=allMarkers;
    wasChanged=false;
    return;
end
m=Topics.select(thisFrame,unames);
a=struct2cell(m); a=vertcat(a{:});
upoints=a(:,2:end);       

%% Check linking matches between lpoints and upoints

cost=inf(size(lpoints,1),size(upoints,1));
for i=1:size(lpoints,1)
    for j=1:size(upoints,1)
        cost(i,j)=norm(lpoints{i,:}-upoints{j,:},2);
    end
end

[matches,ur,uc]=matchpairs(cost,MaxDistance);
lmatches=lnames(matches(:,1));
umatches=unames(matches(:,2));

%% Now use matches to label

 % Each unlabeled point that has a target index
for i=1:size(lmatches,1)   
   if (Verbose==2)
        fprintf('%s->%s @%1.2f\n',lmatches{i},umatches{i},frameloc);
   end   
   %So, lets grab the data from the last gap up to the next gap of the upoint.
   udata=unlabeledMarkers.(umatches{i});
   % Find previous gap and next gap of udata       
   a=isnan(udata{:,2:end});
   hasAll=~any(a,2);
   mask=udata.Header<frameloc;
   previousGapIdx=find(((~hasAll) & mask),1,'last');
   nextGapIdx=find(((~hasAll) & ~mask),1,'first');
   if isempty(nextGapIdx); nextGapIdx=numel(hasAll)+1; end
   if isempty(previousGapIdx); previousGapIdx=0; end

   ustart=udata.Header(previousGapIdx+1);
   uend=udata.Header(nextGapIdx-1);       
   a=Topics.cut(unlabeledMarkers,ustart,uend,umatches(i));
   utable=a.(umatches{i});
   % Insert the unlabeled data into the labeled marker
   z=labeledMarkers.(lmatches{i});
   z{previousGapIdx+1:nextGapIdx-1,:}=utable.Variables;
   labeledMarkers.(lmatches{i})=z; 
   % Remove the unlabeled data from the unlabeled marker
   utable{:,2:end}=nan*utable{:,2:end};
   z=unlabeledMarkers.(umatches{i});
   z{previousGapIdx+1:nextGapIdx-1,:}=utable.Variables;
   unlabeledMarkers.(umatches{i})=z;
   wasChanged=true;   
end

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
    interpMarkers=Topics.interpolate(markers,i,allmarkers);
    markers=interpMarkers; % Add some mask to avoid extrapolating too far
    
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




