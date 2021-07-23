function [allMarkers,removedData]=Label(allMarkers,frame,matches,varargin)
% function relabeledMarkers=Label(allMarkers,frame,matches,OPTIONAL)
% Label markers by assigning the labels (matches{i,2}) to the markers
% (matches{i,1}) for trajectories that contain a given frame.
% matches is a cell arraythat contain the name of the label
% replace label and original label on each row.
% 
%       Verbose  - (0) minimal output, 1 normal, 2 debug mode
%

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);

p.parse(varargin{:});
Verbose = p.Results.Verbose;

removedData=Topics.select(allMarkers,matches(:,2));
removedData=Topics.transform(@(x)(x*nan),removedData);

% Recursive for multiple matches
if size(matches,1)>1
    for i=1:size(matches,1)
        match=matches(i,:);
       [allMarkers,removedDataNew]=Vicon.Labeling.Label(allMarkers,frame,match,varargin{:});
       removedData=Topics.merge(removedData,removedDataNew);
    end
    return;
end

%% Extract names for convenience
match=matches;
omarker=match{1}; rmarker=match{2};

if (Verbose>1)
fprintf('\t%s->%s @%1.2f\n',match{1},match{2},frame);
end   

%   omarker                    gap.--------frame-----.gap
%   rmarker                          gap.--frame-----------.gap
%   rmarker(extended)      gap.<-----gap.--frame-----------.gap
%   I want to move data from omarker to rmarker

% Determine the beginning and end of the section for each marker
intervals=Vicon.extendIntervals(struct(omarker,{{[frame,frame]}}),allMarkers,'Direction','whole');
intervals=intervals.(omarker){1}; ostart=intervals(1); oend=intervals(2);              
% Determine the beginning and end of the section for each marker
intervals=Vicon.extendIntervals(struct(rmarker,{{[frame,frame]}}),allMarkers,'Direction','whole');
intervals=intervals.(rmarker){1}; rstart=intervals(1); rend=intervals(2);              

% Determine the beginning and end of the extended section of rmarker around
% otails.
intervals=Vicon.extendIntervals(struct(rmarker,{{[ostart,oend]}}),allMarkers,'Direction','whole');
intervals=intervals.(rmarker){1}; rostart=intervals(1); roend=intervals(2);              

rsection=Topics.cut(allMarkers,rstart,rend,rmarker);
osection=Topics.cut(allMarkers,ostart,oend,omarker);
rosection=Topics.cut(allMarkers,rostart,roend,rmarker);

% Ideal cases: no rmarker data is removed when moving data to rmarker
% i.e. rmarker between rstart and rend is all nan.
if isempty(rsection.(rmarker)) || all(isnan(rsection.(rmarker){:,2:end}),'all')
    %Copy osection to rmarker 
    tbl=osection.(omarker);
    allMarkers=Topics.merge(allMarkers,struct(rmarker,tbl));
    %Clear osection from omarker
    tbl{:,2:end}=nan;
    allMarkers=Topics.merge(allMarkers,struct(omarker,tbl));    
    return;
end
% Also when rsection is contained within osection.
if (ostart==rostart) && (oend==roend)
    %Copy osection to rmarker
    tbl=osection.(omarker);
    allMarkers=Topics.merge(allMarkers,struct(rmarker,tbl));
    %Copy rosection to omarker
    tbl=rosection.(rmarker);
    allMarkers=Topics.merge(allMarkers,struct(omarker,tbl));
    return;
end

% Other cases are when data is removed when moving from osection to rmarker
% This is when rosection crosses osection.
if (rostart<ostart) || (roend>oend)
    % Check if rosection is the same as rsection
    if (rostart==rstart) && (roend==rend)
        %The rmarker section is actually bigger than the osection label in
        %the other direction.
        [allMarkers,removedData]=Vicon.Labeling.Label(allMarkers,frame,fliplr(match),varargin{:});
        return;        
    elseif (rostart<ostart) || (roend>oend)
        % Copy osection to rmarker and unlabel rsection
        tbl=osection.(omarker);
        allMarkers=Topics.merge(allMarkers,struct(rmarker,tbl));
        tbl=rosection.(rmarker);
        allnames=fieldnames(allMarkers); newname=sprintf('C_%d',numel(allnames)+1);
        newtbl=allMarkers.(allnames{1}); newtbl{:,2:end}=nan;
        allMarkers.(newname)=newtbl;
        newdata.(newname)=tbl;
        allMarkers=Topics.merge(allMarkers,newdata);        
        return;
    end
end                          
    
end

