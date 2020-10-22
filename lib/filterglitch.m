function x=filterglitch(x,minwidth)
% x=filterglitch(x,minwidth)
% For a logical signal produce a digital output that has low or high
% sections of a minimum width.

isrow=false;
if size(x,1)==1
    isrow=true;
    x=x';
end

x=logical(x);
%assert(x(1)==0,'x(1) must be 0');

a=abs([0; diff(x)]);

idx=find(a);

intervals=[idx(1:end-1) idx(2:end)];
width=diff(intervals,[],2);

[sortedWidth,sortedIdx]=sort(width,'ascend');
sortedIntervals=intervals(sortedIdx,:);

for i=1:sum(sortedWidth<=minwidth)        
    interval=sortedIntervals(i,:);
    x(interval(1):interval(2))=x(interval(1)-1);
end

%{
lastidx=1;

for i=1:numel(idx)
    curidx=idx(i);
    if ((curidx-lastidx)<minwidth)
        x(lastidx:curidx)=x(max([lastidx,1]));
    elseif x(curidx)
        x(lastidx:curidx-1)=0;
    else
        x(lastidx:curidx-1)=1;
    end
    lastidx=curidx;
end
%}

if isrow
    x=x';
end

end
