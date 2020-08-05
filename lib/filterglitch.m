function x=filterglitch(x,minwidth)
% x=filterglitch(x,minwidth)
% For a logical signal produce a digital output that has low sections of 
% a minimum width.

isrow=false;
if size(x,1)==1
    isrow=true;
    x=x';
end

x=logical(x);
%assert(x(1)==0,'x(1) must be 0');

a=abs([0; diff(x)]);

idx=find(a);

lastidx=1;

for i=1:numel(idx)
    curidx=idx(i);
    if ((curidx-lastidx)<minwidth)
        x(lastidx:curidx)=x(lastidx);
    elseif x(curidx)
        x(lastidx:curidx-1)=0;
    else
        x(lastidx:curidx-1)=1;
    end
    lastidx=curidx;
end

if isrow
    x=x';
end

end
