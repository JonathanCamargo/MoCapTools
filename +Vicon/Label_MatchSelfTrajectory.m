function matches=Label_MatchSelfTrajectory(allmarkers,frame,varargin)
% Find matches between unlabeled markers and labels based on the
% interpolation/extrapolation of each marker trajectory to unlabeled
% frames.
%
% This function can be used stand alone or as part of
% Vicon.Label.
% 
% matches=Label_MatchSelfTrajectory(allmarkers,frame,varargin)
%
% allmarkers: is the marker structure as found with Vicon.ExtractMarkers
% segmentMarkers: is the structure containing the mapping from
% labels to segments and segments to labels found with
% Vicon.getSegmentMarkers (from .vsk files) or Osim.model.getSegmentMarkers (from .osim
% files).

%
% Optional parameters:



    p=inputParser();          
    p.addParameter('MaxDistance',10);
    p.addParameter('MaxWindow',10); % Max window of frames for a valid interpolation (extrapolation)
    p.addParameter('Verbose',10);
    p.parse(varargin{:});
    
    MaxDistance=p.Results.MaxDistance;
    MaxWindow=p.Results.MaxWindow;
    Verbose=p.Results.Verbose;
    allmarkers=Osim.interpret(allmarkers,'TRC','struct');
    
   
    %% Get the frame data
    thisFrame=Topics.cut(allmarkers,frame,frame);
    [allnames,umarkers,unames,lmarkers,lnames]=Vicon.MarkerCategories(thisFrame);
    isnanlmarkers=Topics.processTopics(@(x)any(isnan(x.Variables),2),lmarkers);
    ulnames=lnames(struct2array(isnanlmarkers)); %This are the markers that are not assigned to this frame
    
    matches={};
    
    section=Topics.cut(allmarkers,frame-100,frame+100);
    
    %% For efficiency only work with lmarkers that are not labeled at this frame and
    % umarkers that exist at this frame.
    [~,ind]=ismember(lnames,allnames);
    % Get all the points from missing labeled markers    
    hasNaN=struct2array(Topics.processTopics(@(x)(any(isnan(x.Variables),2)),thisFrame));        
    isMissing=hasNaN(ind);
    lnames=lnames(isMissing);
    if isempty(lnames)
        if (Verbose>0)
            fprintf('No missing markers in frame header=%f\n',frame);
        end    
        return;
    end
    m=Topics.select(section,lnames);
    predicted=predictPosition(m,frame,MaxWindow);
    a=struct2cell(predicted); a=vertcat(a{:});
    lpoints=a(:,2:end); 
    lpoints=lpoints(~any(isnan(lpoints.Variables),2),:);
    lnames=lnames(~any(isnan(lpoints.Variables),2),:);

    % Get all the points from existing unlabeled markers
    [~,ind]=ismember(unames,allnames);
    isMissing=hasNaN(ind);
    unames=unames(~isMissing);
    if isempty(unames)
        if (Verbose>0)
            fprintf('No unlabeled markers in frame header=%1.2f\n',frame);
        end     
        return;
    end
    m=Topics.select(thisFrame,unames,'Search','strcmp');
    a=struct2cell(m); a=vertcat(a{:});
    upoints=a(:,2:end);       

    %% Check linking matches between lpoints and upoints
    cost=inf(size(lpoints,1),size(upoints,1));
    for i=1:size(lpoints,1)
        for j=1:size(upoints,1)
            cost(i,j)=norm(lpoints{i,:}-upoints{j,:},2);
        end
    end
    
    % Use matchPairs to find the optimal cost assignement
    [matches,~,~]=matchpairs(cost,MaxDistance);
    lmatches=lnames(matches(:,1));
    umatches=unames(matches(:,2));
    matches=[umatches,lmatches];
end



%% %%%%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smoothedTable=smoothTable(tableData)
    N=ceil(height(tableData)/10);   
    a=[smooth(tableData.x,N),smooth(tableData.y,N),smooth(tableData.z,N)];
    varNames=tableData.Properties.VariableNames;
    smoothedTable=array2table([tableData.Header a],'VariableNames',{'Header',varNames{2:end}});
end

function markers=predictPosition(markers,frame,window)
    % For a marker set determine the position of the markers at a given
    % time.
    allmarkers=fieldnames(markers);
    %Smooth first to make it better   
    markers=Topics.processTopics(@smoothTable,markers,allmarkers,'Parallel',true);
    interpMarkers=Topics.interpolate(markers,frame,allmarkers);
    % Avoid extrapolating too far
    zoom=Topics.cut(markers,frame-window,frame+window);
    allnan=Topics.processTopics(@(x)(all(isnan(x{:,2:end}),'all')),zoom);
    for i=1:numel(allmarkers)
        marker=allmarkers{i};
        if allnan.(marker)
            a=interpMarkers.(marker);
            a{:,2:end}=inf;
            interpMarkers.(marker)=a;
        end
    end
                
            
        
    
    
    markers=interpMarkers; 
    
end
