function intervals = extendIntervals(intervals,allMarkers,varargin)
% intervals = extendIntervals(intervals,allMarkers,varargin)
%
% Extend an interval of frames to reach the head and tail of the
% trajectorty.
%  
%  Options:
%       Extend -  'forward' / 'backward' / ('whole') Extends the
%       intervals to the next/previous/(or both) sections of trajectory.
%
%  -----.gap.----a------b-------.gap.---------
%  Shifts the interval to be
%  -----.gap.a----------b-------.gap.--------- (backward)
%  -----.gap.----a-------------b.gap.--------- (forward)
%  -----.gap.a-----------------b.gap.--------- (whole)


validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);
p.addParameter('Direction','whole');
p.parse(varargin{:});
Verbose = p.Results.Verbose;
Direction = p.Results.Direction;

markerNames=fieldnames(intervals);
isnanstruct=Topics.transform(@(x)(any(isnan(x(:,2:end)),2)),Topics.select(allMarkers,markerNames));
if strcmp(Direction,'forward')     
    for i=1:numel(markerNames)
       marker=markerNames{i};
       intervals.(marker)=ExtendForward(intervals.(marker),isnanstruct.(marker));
    end            
elseif strcmp(Direction,'backward')
    for i=1:numel(markerNames)
       marker=markerNames{i};
       intervals.(marker)=ExtendBackward(intervals.(marker),isnanstruct.(marker));
    end        
elseif strcmp(Direction,'whole')
    for i=1:numel(markerNames)
       marker=markerNames{i};
       a=ExtendBackward(intervals.(marker),isnanstruct.(marker));
       b=ExtendForward(intervals.(marker),isnanstruct.(marker));
       c=cell2mat([a b]); c=c(:,[1 end]);
       intervals.(marker)=mat2cell(c,ones(size(c,1),1),2);
       
    end        
end
end

function intervals=ExtendForward(intervals,isnanframe)
    for i=1:numel(intervals)
        %Find the next frame that has nan (or last frame)
        interval=intervals{i};                
        nextFrameIdx=find(isnanframe.Header>=interval(2) & isnanframe{:,2},1,'first');
        if isempty(nextFrameIdx)
            nextFrame=isnanframe.Header(end);
        else
            nextFrameIdx=max([nextFrameIdx-1,1]);
            nextFrame=max([isnanframe.Header(nextFrameIdx),interval(2)]);
        end
        interval=[interval(1) nextFrame];
        intervals{i}=interval;
    end    
end

function intervals=ExtendBackward(intervals,isnanframe)
    for i=1:numel(intervals)
        %Find the next frame that has nan (or initial frame)
        interval=intervals{i};                
        nextFrameIdx=find(isnanframe.Header<=interval(1) & isnanframe{:,2},1,'last');
        if isempty(nextFrameIdx)
            nextFrame=isnanframe.Header(1);
        else
            nextFrame=min([interval(1) isnanframe.Header(min([nextFrameIdx+1,size(isnanframe,1)]))]);
        end
        interval=[nextFrame interval(2)];
        intervals{i}=interval;
    end    
end

