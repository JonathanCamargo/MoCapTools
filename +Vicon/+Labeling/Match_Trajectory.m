function matches=Match_Trajectory(allmarkers,frame,varargin)
% Find matches between markers that are not labeled in the frame to markers
% that exist in the frame based on the  interpolation/extrapolation
% of each marker trajectory. Returns a cell array with two columns where
% each row defines a match. (original label->replacement label)
%
% This function can be used stand alone or as part of
% Vicon.Label.
% 
% matches=Label_MatchSelfTrajectory(allmarkers,frame,varargin)
%
% allmarkers: is the marker structure as found with Vicon.ExtractMarkers
% frame: the frame where the matching is analized.
%
% Optional parameters:
% 'IncludeLabeled' (false)/true add other labeled marker to the matching.



    p=inputParser();          
    p.addParameter('MaxDistance',10,@isnumeric); %Max distance tolerable for a valid match
    p.addParameter('MaxWindow',25,@isnumeric); % Max window of frames for a valid interpolation (extrapolation)
    p.addParameter('IncludeLabeled',true,@islogical);
    p.addParameter('Verbose',2);
    p.parse(varargin{:});
    
    MaxDistance=p.Results.MaxDistance;
    MaxWindow=p.Results.MaxWindow;
    Verbose=p.Results.Verbose;
    IncludeLabeled=p.Results.IncludeLabeled;
    allmarkers=Osim.interpret(allmarkers,'TRC','struct');
       
    %% Get the frame data
    thisFrame=Topics.cut(allmarkers,frame,frame);
    [allnames,umarkers,unames,lmarkers,lnames]=Vicon.MarkerCategories(thisFrame);
    isnanlmarkers=Topics.processTopics(@(x)any(isnan(x.Variables),2),lmarkers);
    ulnames=lnames(struct2array(isnanlmarkers)); %This are the markers that are not assigned to this frame
    
    matches={};
    
    section=Topics.cut(allmarkers,frame-100,frame+100);
    
    %% For efficiency only work with lmarkers that are not labeled at this frame and
    % umarkers that exist at this frame. if IncludeLabeled markers is
    % enabled add other lmarkers that are labeled at this frame to the
    % possible umarkers.
    
    [~,ind]=ismember(lnames,allnames);
    % Get all the points from missing labeled markers    
    hasNaN=struct2array(Topics.processTopics(@(x)(any(isnan(x.Variables),2)),thisFrame));        
    isMissing=hasNaN(ind);
    ulnames=lnames(isMissing);
    if isempty(ulnames)
        if (Verbose>0)
            fprintf('No missing markers in frame header=%f\n',frame);
        end    
        return;
    end
    m=Topics.select(section,ulnames);
    predicted=predictPosition(m,frame,MaxWindow);
    a=struct2cell(predicted); a=vertcat(a{:});
    ulnames=fieldnames(predicted);
    ulpoints=a(:,2:end); 
    
    if isempty(ulpoints)
        return;
    end
    
    ulpoints=ulpoints(~any(isnan(ulpoints.Variables),2),:);
    ulnames=ulnames(~any(isnan(ulpoints.Variables),2),:);

    % Get all the points from existing unlabeled markers
    [~,ind]=ismember(unames,allnames);
    notMissing=hasNaN(ind);
    unames=unames(~notMissing);
    if isempty(unames) && ~IncludeLabeled
        if (Verbose>0)
            fprintf('No unlabeled markers in frame header=%1.2f\n',frame);
        end     
        return;
    end
    if ~isempty(unames)
        m=Topics.select(thisFrame,unames,'Search','strcmp');
        a=struct2cell(m); a=vertcat(a{:});
        upoints=a(:,2:end);
    else
        upoints=[];
    end
    
    if IncludeLabeled
        % Get all the points from labeled markers that are present in this
        % frame.
        [~,ind]=ismember(lnames,allnames);
        notMissing=~hasNaN(ind);
        olnames=lnames(notMissing);
        if ~isempty(olnames)
            m=Topics.select(thisFrame,olnames,'Search','strcmp');
            a=struct2cell(m); a=vertcat(a{:});
            olpoints=a(:,2:end);
            upoints=[upoints;olpoints];
            unames=[unames;olnames];
        end        
    end
    
    %% Check linking matches between lpoints and upoints
    cost=inf(size(ulpoints,1),size(upoints,1));
    for i=1:size(ulpoints,1)
        for j=1:size(upoints,1)
            cost(i,j)=norm(ulpoints{i,:}-upoints{j,:},2);
        end
    end
    
    % Use matchPairs to find the optimal cost assignement
    [matches,~,~]=matchpairs(cost,MaxDistance);
    lmatches=ulnames(matches(:,1));
    umatches=unames(matches(:,2));   
    matches=[umatches,lmatches];
end



%% %%%%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smoothedTable=smoothTable(tableData)
    %N=ceil(height(tableData)/10);   
    %a=[smooth(tableData.x,N),smooth(tableData.y,N),smooth(tableData.z,N)];
    %varNames=tableData.Properties.VariableNames;    
    %smoothedTable=array2table([tableData.Header a],'VariableNames',{'Header',varNames{2:end}});
    notnan=~any(isnan(tableData.Variables),2);
    smoothedTable=tableData(notnan,:);
end

function markers=predictPosition(markers,frame,window)
    % For a marker set determine the position of the markers at a given
    % time.
    allmarkers=fieldnames(markers);
    %Smooth first to make it better %This is bad
    thisMarkers=Topics.processTopics(@smoothTable,markers,allmarkers,'Parallel',true);    
    interpMarkers=Topics.interpolate(thisMarkers,frame,allmarkers,'Extrapolation',true);
    % Avoid extrapolating too far
    zoom=Topics.cut(markers,frame-window,frame+window);
    allnan=Topics.processTopics(@(x)(all(isnan(x{:,2:end}),'all')),zoom);
    hasdata=Topics.processTopics(@(x)(size(x,1)),interpMarkers);
    for i=1:numel(allmarkers)
        marker=allmarkers{i};
        if allnan.(marker) || ~hasdata.(marker)
            interpMarkers=rmfield(interpMarkers,marker);            
        end
    end   
    markers=interpMarkers;     
end
