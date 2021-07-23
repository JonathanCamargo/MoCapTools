function matches=Match_DonorDistance(allmarkers,frame,segmentMarkers,varargin)
% matches=Match_DonorDistance(allmarkers,frame,segmentMarkers,varargin)
% Find matches between unlabeled markers and labels based on the relative
% distance from the unlabeled markers to other markers within the same
% segment.  Returns a 2 column cell array with the names of unlabeled
% markers and the labels to assign.
%
% This function can be used stand alone or as part of
% Vicon.Labeling.Label.
%
% allmarkers: is the marker structure as found with Vicon.ExtractMarkers
% frame: is the frame value
% segmentMarkers: is the structure containing the mapping from
% labels to segments and segments to labels found with
% Vicon.getSegmentMarkers (from .vsk files) or Osim.model.getSegmentMarkers (from .osim
% files).
%
% Optional parameters:
% 'RelativeDistances': M (a matrix that contains the relative distance from
%  every label to each other. Preferably compute this from a static trial
%  using Vicon.Label_ComputeDistances. If not passed the matrix is computed
%  with the data in allmarkers.


    p=inputParser();    
    p.addParameter('RelativeDistances',[]);
    p.addParameter('MaxDistance',20); 


    p.parse(varargin{:});
    M=p.Results.RelativeDistances;
    MaxDistance=p.Results.MaxDistance;
    allmarkers=Osim.interpret(allmarkers,'TRC','struct');
    
    if isempty(M)    
       M=Vicon.Label_ComputeDistances(allmarkers);
    end
    
    matches=[];
    
    %% Get the frame data
    thisFrame=Topics.cut(allmarkers,frame,frame);
    [~,umarkers,unames,lmarkers,lnames]=Vicon.MarkerCategories(thisFrame);
    
    if isempty(unames)
        return;
    end
    
    isnanlmarkers=Topics.processTopics(@(x)any(isnan(x.Variables),2),lmarkers);
    isnanumarkers=Topics.processTopics(@(x)any(isnan(x.Variables),2),umarkers);
    ulnames=lnames(struct2array(isnanlmarkers)); %This are the markers that are not assigned to this frame
    unames=unames(~struct2array(isnanumarkers)); %This are the markers that are not assigned to this frame
    
    if (isempty(ulnames) || isempty(unames))
        return;
    end

    %% Now find the distance from each of those markers to the markers that are
    % present.
    % Cost matrix ulnames x unames
    cost=inf*ones(numel(unames),numel(ulnames));
    [~,lnameIdx]=ismember(ulnames,lnames); % Find the indices of unlabeled labels in the labels list.

    %% Create a cost matrix

    % For each umarker suppose that it is a ulmarker and compute the distances
    for i=1:numel(unames)
        thisuname=unames{i};
        umarker=umarkers.(thisuname);    
        for j=1:numel(ulnames)
            thisulname=ulnames{j};
            
            % Assume that umarker corresponds to ulmarker. First
            % determine if that is really possible.            
            % Check if umarker around this frame conflicts  with ulmarker
            % around this frame. If there is conclict it means that ulmarker
            % comes from a different trajectory and should not stitch to umarker.
            
            s=Topics.select(allmarkers,{thisuname});
            intervals=struct(thisuname,{{[frame frame]}});
            intervals=Vicon.extendIntervals(intervals,s,'Direction','whole');            
            uinterval=intervals.(thisuname){1}; 
            
            s=Topics.cut(allmarkers,uinterval(1),uinterval(2),{thisuname,thisulname});
            % Data conflict if thisulname has any data within thisuname
            % interval. If that happens skip.
            tbl=s.(thisulname); 
            if any(~isnan(tbl{:,2:end}),'all')
               continue; 
            end            
            
            %Get Donors and skip if they don't exist
            thisSegmentMarkers=segmentMarkers.(segmentMarkers.(thisulname));
            otherNames=setdiff(thisSegmentMarkers,thisulname); 
            if isempty(otherNames)
                continue;
            end
            
            %Get Donors and skip if they don't exist
            otherMarkers=Topics.select(thisFrame,otherNames);
            hasNan=Topics.processTopics(@(x)(any(isnan(x.Variables),'all')),otherMarkers);        
            otherNames=otherNames(~struct2array(hasNan));
            if isempty(otherNames)
                continue;
            end
            otherMarkers=Topics.select(thisFrame,otherNames);
            [~,otherNameIdx]=ismember(otherNames,lnames);

            %Find the distance from umarker to to each otherName
            x=umarker{:,2:end};
            y=struct2cell(otherMarkers); y=vertcat(y{:}); y=y{:,2:end};            
            distances=GetDistance(x,y);
            groundTruth=M(lnameIdx(j),otherNameIdx);
            % Compare distances to ground truth and assign to cost        
            cost(i,j)=mean(abs(distances-groundTruth));                
            % Now we have a matrix with all the distances  
            if isempty(otherMarkers)
                continue; % No other markers present in this frame
            end
        end
    end

    %% Use matchPairs to find the optimal cost assignement   
    cost(isnan(cost))=inf;
    [matches,~,~]=matchpairs(cost,MaxDistance);
    umatches=unames(matches(:,1));
    ulmatches=ulnames(matches(:,2));
    matches=[umatches,ulmatches];
end

%% %%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%
function distance=GetDistance(x,y)
% For a matrix x (NxM) and a matrix y (QxM) compute
% the distance in Rm between each sample in N vs each sample in Q.
[xi,yi]=ndgrid(1:size(x,1),1:size(y,1));
X=x(xi(:),:);
Y=y(yi(:),:);
distance=vecnorm((X-Y),2,2);
distance=reshape(distance,size(x,1),size(y,1));
end