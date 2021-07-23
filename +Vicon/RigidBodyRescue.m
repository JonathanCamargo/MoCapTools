function newMarkers = RigidBodyRescue(allMarkers,staticMarkers,targetMarker,donors)
% Rescue marker by using marker data from a scaled model file
% This function uses a static marker information to estimate the position
% of a target marker by preserve relative distance to donors in the static.
%
% RigidBodyRescue(allMarkers,staticMarkers,targetMarker,donors)

%% Completely reconstruct R_PSIS from 'L_ASIS','L_PSIS','R_PSIS' matching model pattern.
sigfoptions={'VerboseLevel',2,'MakeGaps',false};
newMarkers=allMarkers;
if size(allMarkers.(donors{1}),1)>1
    try
        newMarkers=Vicon.SectionalIterativeGapFilling(allMarkers,sigfoptions{:});
    catch        
    end
end
donorData=Topics.select(newMarkers,donors);

%% For all the frames in the static
a=Topics.consolidate(staticMarkers,[donors targetMarker],'Prepend',true);
isFullFrame=~any(isnan(a.Variables),2);
intervalsIdx=splitLogical(isFullFrame);
intervals=cellfun(@(x)(a.Header(x)),intervalsIdx,'Uni',0);
staticMarkers=Topics.cut(staticMarkers,intervals{1}(1),intervals{1}(end),[donors, targetMarker]);
staticData=Topics.select(staticMarkers,[donors, targetMarker]);
staticMean=Topics.processTopics(@(x)(mean(x.Variables,1)),staticData,[donors, targetMarker]);
donorDataStaticMean=Topics.select(staticMean,donors);
b=cell2mat(struct2cell(donorDataStaticMean)); b=b(:,2:end);
x0=b';
%Centroid for static
c0=mean(x0,2);
%Distance to desired point in static
p0=staticMean.(targetMarker)(2:end)';

if ~ismember(fieldnames(newMarkers),targetMarker)
    newMarkers.(targetMarker)=donorData.(donors{1});
    newMarkers.(targetMarker){:,2:end}=nan;
    % newMarkers.test=newMarkers.(targetMarker); % add a test marker to
    % check visually.
end

header=donorData.(donors{1}).Header;
% Only use frames where all donors have information and target marker does
% not.

hasTargetData=~any(isnan(newMarkers.(targetMarker).Variables),2);

a=Topics.consolidate(donorData,donors,'Prepend',true); 
hasNaN=any(isnan(a.Variables),2);

isToRescue=(~hasNaN) & (~hasTargetData);
header=header(isToRescue);
indices=find(isToRescue);

%% Find marker for each
for i=1:numel(header)
    thisFrame=Topics.cut(donorData,header(i),header(i),donors);
    a=Topics.consolidate(thisFrame,donors,'Prepend',true);
    a=reshape(a{:,2:end},3,numel(donors))';
    x1=a';
    %This centroid
    c1=mean(x1,2);
    %Distance to every donor from the model
    %Find rotation matrix from x0 to x1
    H=(x1-c1)*(x0-c0)';
    [U,~,V]=svd(H);
    L = eye(3);
    if det(U * V') < 0
        L(3, 3) = -1;
    end
    R = V * L * U';
    
    % Plot this
    %x1c=x1-c1;
    %x0c=x0-c0;
    %plot3(x1c(1,:),x1c(2,:),x1c(3,:),'b.'); hold on;
    %plot3(x0c(1,:),x0c(2,:),x0c(3,:),'r.'); hold on;
    %H00=[eye(3) zeros(3,1); 0 0 0 1];    
    %trplot(eye(3),'length',100,'color','r');
    %trplot(R,'length',100,'color','b');
    %tr2rpy(R)    
    
    %Now use the distance from c0 to p0 to find p1
    p1=(R'*(p0-c0))+c1;  
    %Add p1 for this frame
    newMarkers.(targetMarker){indices(i),2:end}=p1';
    %newMarkers.test{indices(i),2:end}=c1'; %Add centroid as a test marker
end
end

