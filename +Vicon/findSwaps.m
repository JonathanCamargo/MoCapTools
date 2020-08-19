function intervals = findSwaps(allMarkers,varargin)
% intervals = FindSwaps(allMarkers,varargin)
% For a marker structure determine swapping of markers by
% observing high changes of velocity. It generates intervals that contain
% sections of marker data that have high acceleration at the ends and high
% velocity within them.
%
%
%
%  Options:
%       VerboseLevel  - (0) minimal output, 1 normal, 2 debug mode
%       MaxVelocity - (10)
%       MaxAcceleration - (3)
%       MinWidth - (1)  minimum width of section between velocity changes.
%       Extend - (false) / 'forward' / 'backward' / 'whole' Extends the
%       intervals to the next/previous/(or both) sections of trajectory.
%

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);
p.addParameter('MaxVelocity',30, validScalar);
p.addParameter('MaxAcceleration',3, validScalar);
p.addParameter('MinWidth',3, validScalar);
p.addParameter('Extend',false);

%p.addParameter('MaxIterations',2,@isnumeric);
%p.addParameter('StartAndEndMaxIterations',nan,@isnumeric);
%p.addParameter('GapMaxIterations',nan,@isnumeric);
p.parse(varargin{:});
Verbose = p.Results.Verbose;
Extend = p.Results.Extend;
MaxVelocity= p.Results.MaxVelocity;
MaxAcceleration= p.Results.MaxAcceleration;
MinWidth=p.Results.MinWidth;
velocity=Topics.processTopics(@gradienty,allMarkers);
acceleration=Topics.processTopics(@gradienty,velocity);
normvelocity=Topics.transform(@(x)vecnorm(x,2,2),velocity);
normacceleration=Topics.transform(@(x)vecnorm(x,2,2),acceleration);

[allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = Vicon.MarkerCategories(allMarkers);

intervals=struct();
for markerIdx=1:numel(labeledMarkerNames)
    marker=labeledMarkerNames{markerIdx};       
    
    header=velocity.(marker).Header;
    v=velocity.(marker){:,2:end}; a=acceleration.(marker){:,2:end}; 
    normv=normvelocity.(marker){:,2:end}; norma=normacceleration.(marker){:,2:end}; 
    vunit=v./normv;
    acctraj=vecnorm(dot(vunit,a,2),2,2);
    acctang=sqrt(norma.^2-acctraj.^2);
    idxa=isoutlier(acctang,'mean','ThresholdFactor',5) & (acctang>MaxAcceleration);    
    idxv=normv>MaxVelocity;
    idx=filterglitch(idxv,MinWidth);
    %{
    % plot    
    offset=2000;%20000;
    subplot(4,1,1)
    plot(header-offset,norma); hold on;
    plot(header-offset,idx*max(norma));
    subplot(4,1,2)
    plot(header-offset,acctraj);hold on;
    plot(header-offset,idx*max(acctraj));
    subplot(4,1,3)
    plot(header-offset,acctang);hold on;
    plot(header-offset,idx*max(acctang));
    subplot(4,1,4)
    plot(header-offset,normv);hold on;
    plot(header-offset,idx*max(normv));
    %}
    % Find the intervals where marker swapping occur
    a=zeros(size(header)); a(idx)=1;
    if any(idx)        
        intervals.(marker)=cellfun(@(x)([header(x(1)) header(x(end))]),splitLogical(a),'Uni',0);
    end
end

markerNames=fieldnames(intervals);
isnanstruct=Topics.transform(@(x)(any(isnan(x(:,2:end)),2)),Topics.select(allMarkers,markerNames));
if strcmp(Extend,'forward')     
    for i=1:numel(markerNames)
       marker=markerNames{i};
       intervals.(marker)=ExtendForward(intervals.(marker),isnanstruct.(marker));
    end            
elseif strcmp(Extend,'backward')
    for i=1:numel(markerNames)
       marker=markerNames{i};
       intervals.(marker)=ExtendBackward(intervals.(marker),isnanstruct.(marker));
    end        
elseif strcmp(Extend,'whole')
    for i=1:numel(markerNames)
       marker=markerNames{i};
       intervals.(marker)=ExtendForward(intervals.(marker),isnanstruct.(marker));
       intervals.(marker)=ExtendBackward(intervals.(marker),isnanstruct.(marker));
    end        
end
end

function out=gradienty(tabledata)
   [~,y]=gradient(tabledata{:,2:end});
   out=tabledata; out{:,2:end}=y;
end

function intervals=ExtendForward(intervals,isnanframe)
    for i=1:numel(intervals)
        %Find the next frame that has nan (or last frame)
        interval=intervals{i};                
        nextFrame=find(isnanframe.Header>interval(2) & isnanframe{:,2},1,'first');
        if isempty(nextFrame)
            nextFrame=isnanframe.Header(end);
        end        
        interval=[interval(1) nextFrame];
        intervals{i}=interval;
    end    
end

function intervals=ExtendBackward(intervals,isnanframe)
    for i=1:numel(intervals)
        %Find the next frame that has nan (or last frame)
        interval=intervals{i};        
        nextFrame=find(isnanframe.Header<interval(1) & isnanframe{:,2},1,'last');
        if isempty(nextFrame)
            nextFrame=isnanframe.Header(1);
        end        
        interval=[nextFrame interval(2)];
        intervals{i}=interval;
    end    
end

