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
%       MinWidth - (1)  minimum width of section between velocity changes.%       
%       intervals to the next/previous/(or both) sections of trajectory.
%

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);
p.addParameter('IncludeUnlabeled',false);
%p.addParameter('MaxVelocity',30, validScalar);
%p.addParameter('MaxAcceleration',3, validScalar);
p.addParameter('MinWidth',3, validScalar);

%p.addParameter('MaxIterations',2,@isnumeric);
%p.addParameter('StartAndEndMaxIterations',nan,@isnumeric);
%p.addParameter('GapMaxIterations',nan,@isnumeric);
p.parse(varargin{:});
Verbose = p.Results.Verbose;
IncludeUnlabeled=p.Results.IncludeUnlabeled;

%MaxVelocity= p.Results.MaxVelocity;
%MaxAcceleration= p.Results.MaxAcceleration;
MinWidth=p.Results.MinWidth;
velocity=Topics.processTopics(@gradienty,allMarkers);
acceleration=Topics.processTopics(@gradienty,velocity);
normvelocity=Topics.transform(@(x)vecnorm(x,2,2),velocity);
normacceleration=Topics.transform(@(x)vecnorm(x,2,2),acceleration);

[allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = Vicon.MarkerCategories(allMarkers);

if IncludeUnlabeled
    markerNames=allMarkerNames;
else
    markerNames=labeledMarkerNames;
end

intervals=struct();

for markerIdx=1:numel(markerNames)
    marker=markerNames{markerIdx};       
    
    header=velocity.(marker).Header;
    v=velocity.(marker){:,2:end}; a=acceleration.(marker){:,2:end}; 
    normv=normvelocity.(marker){:,2:end}; norma=normacceleration.(marker){:,2:end}; 
    vunit=v./normv;
    acctraj=vecnorm(dot(vunit,a,2),2,2);
    acctang=sqrt(abs(norma.^2-acctraj.^2));
    %idxa=isoutlier(acctang,'mean','ThresholdFactor',5) & (acctang>MaxAcceleration);    
    
    filterednormv=abs(normv-movmean(normv,200));
    idxv=isoutlier(filterednormv,'median','ThresholdFactor',20);
    
    %filteredacctang=abs(acctang-movmean(acctang,200));
    filteredacctang=acctang;
    idxa=isoutlier(filteredacctang,'median','ThresholdFactor',20);
    idxa=(idxa & (filteredacctang>4));
    idx=filterglitch((idxv | idxa),MinWidth);        
    
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

end

function out=gradienty(tabledata)
   nanidx=any(isnan(tabledata{:,2:end}),2);
   if sum(~nanidx)>10
    x=interp1(tabledata.Header(~nanidx),tabledata{~nanidx,2:end},tabledata.Header,'linear');
   else
    x=tabledata{:,2:end};
   end
   x(nanidx,:)=nan;
   [~,y]=gradient(x);
   
   out=tabledata; out{:,2:end}=y;
end

