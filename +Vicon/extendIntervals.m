function intervals = extendIntervals(intervals,allMarkers,varargin)
% Extend the intervals
%  Options:
%       Extend -  'forward' / 'backward' / ('whole') Extends the
%       intervals to the next/previous/(or both) sections of trajectory.
%

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);
p.addParameter('Extend','whole');
p.parse(varargin{:});
Verbose = p.Results.Verbose;
Extend = p.Results.Extend;

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

