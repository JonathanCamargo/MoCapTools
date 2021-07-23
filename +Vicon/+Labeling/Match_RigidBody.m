function matches=Match_RigidBody(allmarkers,frame,staticMarkers,segmentMarkers,varargin)
% matches=Match_RigidBody(allmarkers,frame,segmentMarkers,varargin)
% Find matches between labeled markers and labels based on fitting of a
% rigid body pattern from a static marker set.
%
% This function can be used stand alone or as part of
% Vicon.Labeling.Label.
%
% allmarkers: Markers to check
% frame: frame to inspect
% staticMarkers: Markers from a correctly labeled and filled trial (static trial)
% segmentMarkers: cell array of markers that belong to the rigid body

    p=inputParser();    
    %p.addParameter('RelativeDistances',[]);    
    p.parse(varargin{:});
    
    thisFrame=Topics.cut(allmarkers,frame,frame);
    allnames=fields(staticMarkers);
    staticHeader=staticMarkers.(allnames{1}).Header;
    staticFrame=Topics.cut(staticMarkers,staticHeader(1),staticHeader(1));

    % for each segment in segmentMarkers compute the transformation from the 
    % static to thisFrame's pose.   
    thisSegmentMarkers=segmentMarkers;
    x0tbl=Topics.consolidate(Topics.select(staticFrame,thisSegmentMarkers));   
    thisMarkers=Topics.select(thisFrame,thisSegmentMarkers);
    thisSegmentMarkers=fieldnames(thisMarkers);
    x1tbl=Topics.consolidate(thisMarkers);
    x1=x1tbl{:,2:end}; x1=reshape(x1,3,[]);
    x1cols=x1tbl.Properties.VariableNames(2:end);
    x0=x0tbl{:,x1cols}; x0=reshape(x0,3,[]);
    
    % If not enough donor markers don't do a rigid body match
    if numel(x1cols)/3<3
        matches={};
        return;
    end   

    %%
    %x0=[0, 1, 0, 1; 0, 0 ,-1 ,-1; 0, 0 ,0 ,0 ];
    %x1=(x1'*eul2rotm([0,0,pi/32],'xyz'))';

    % Centroids
    c0=mean(x0,2);
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

    x1c=x1-c1;
    x0c=x0-c0;
    x1cR=(x1c'*R')';

    %{ 
        %Plot this   
        clf
        subplot(2,1,1);
        plot3(x1(1,:),x1(2,:),x1(3,:),'b.'); hold on;
        plot3(x0(1,:),x0(2,:),x0(3,:),'r.'); hold on;
        xlabel('x'); ylabel('y'); zlabel('z');
        for i=1:numel(thisSegmentMarkers)
            text(x0(1,i),x0(2,i),x0(3,i),thisSegmentMarkers{i},'Color','r');
            text(x1(1,i),x1(2,i),x1(3,i),thisSegmentMarkers{i},'Color','b');
        end
        axis equal;
        %view([0 0 1])
        subplot(2,1,2);
        plot3(x1c(1,:),x1c(2,:),x1c(3,:),'b.'); hold on;
        plot3(x1cR(1,:),x1cR(2,:),x1cR(3,:),'bx'); hold on;
        plot3(x0c(1,:),x0c(2,:),x0c(3,:),'r.'); hold on;      
        xlabel('x'); ylabel('y'); zlabel('z');
        for i=1:numel(thisSegmentMarkers)
            text(x0c(1,i),x0c(2,i),x0c(3,i),thisSegmentMarkers{i},'Color','r');
            text(x1cR(1,i),x1cR(2,i),x1cR(3,i),thisSegmentMarkers{i},'Color','b');
        end
        axis equal;
        %view([0 0 1])
    %}

    %% Check all the permutations
    idx=perms(1:numel(thisSegmentMarkers));
    cost=inf(size(idx,1),1);
    for i=1:size(idx,1)
        cost(i)=mean(vecnorm(x0c-x1cR(:,idx(i,:)),2));        
    end
    [mincost,minidx]=min(cost);
    sorted_thisSegmentMarkers=thisSegmentMarkers(idx(minidx,:));

    swapsIdx=~strcmp(thisSegmentMarkers,sorted_thisSegmentMarkers);
    matchesA=thisSegmentMarkers(swapsIdx);
    matchesB=sorted_thisSegmentMarkers(swapsIdx);

    allmatches=[matchesA matchesB];

    if isempty(allmatches)
        matches={};
        return;
    end
    
    matches=allmatches(1,:);
    for i=2:size(allmatches,1)
        if any(ismember(allmatches{i,2},matches(:,1)))
            continue;
        end
        matches=[matches;allmatches(i,:)];
    end
end