function fpnamesTbl = correlateForcePlates2(trctable,fpcornersstruct,varargin)
% fpnames = correlateForceplates(trctable,fpcornersstruct,[optional:fptable],[param:'limits'])
% Provide a table with the names for which the trc table markers are
% within a bounding box of each forceplate. 
% If optional fptable is passed it is used to further refine the result by 
% looking into actual contact force.
% For each frame check if all markers are within bounding box defined
% by the forceplate volume given by its area extended with limits given by
% [dx,dy,dz] with defaults [10,10,100]
%                  
%                  dx |
%              -------------
%              |     FP     |
%        dy<-  | dz:up only | -> +dy
%              -------------
%                  dx |

%%

p=inputParser();
p.addOptional('fp',[],@istable);
p.addParameter('Limits',[10,10,100]);
p.parse(varargin{:});

limits=p.Results.Limits;
fp=p.Results.fp;
fpnames=fieldnames(fpcornersstruct);

if numel(limits)==3
    dxp=limits(1);dyp=limits(2);dzp=0; %Bounding box limits
    dxn=-limits(1);dyn=-limits(2);dzn=-limits(3); %Bounding box limits
elseif numel(limits)==6
    dxn=min(limits([1,4]));dyn=min(limits([2,5]));dzn=min(limits([3,6])); %Bounding box limits
    dxp=max(limits([1,4]));dyp=max(limits([2,5]));dzp=max(limits([3,6])); %Bounding box limits
end

fpnamesTbl=trctable(:,1);
fpnamesTbl.Forceplate=repmat({'NONE'},size(trctable,1),1);

minVmag=10;
for i=1:numel(fpnames)
   fpname=fpnames{i};
   corners=fpcornersstruct.(fpnames{i});
   H=getTransform(reshape(mean(corners{:,2:end},1),3,4));
   
   % Transform trc to the local coordinates of the forceplate
   n=(size(trctable,2)-1)/3;
   trcLocal=trctable{:,2:end}-repmat(H(1:3,4),n,1)';
   trcLocal=Vicon.transform(trcLocal,H(1:3,1:3));

   n=(size(corners,2)-1)/3;
   cornersLocal=corners{:,2:end}-repmat(H(1:3,4),n,1)';
   cornersLocal=Vicon.transform(cornersLocal,H(1:3,1:3));
   
   
   c=reshape(mean(cornersLocal,1),3,4)';
   fpsize=range(c);
   minlim=-fpsize/2+[dxn dyn dzn];
   maxlim=fpsize/2+[dxp dyp dzp];
   
   n=(size(trctable,2)-1)/3;
   minLimits=repmat(repmat(minlim,1,n),size(trctable,1),1);
   maxLimits=repmat(repmat(maxlim,1,n),size(trctable,1),1);
   
   idx=all((trcLocal>minLimits & trcLocal<maxLimits),2);
   
   %%
   %{
   figure(1); clf;   
   t=fpcornersstruct.(fpname).Header(1)+(1:size(trcLocal,1))'-1;
   subplot(3,1,1); col=1;
   plot(t,trcLocal(:,col)); hold on; plot(t,minLimits(:,col),'--');  plot(t,maxLimits(:,col),'--');
   subplot(3,1,2); col=2;
   plot(t,trcLocal(:,col)); hold on; plot(t,minLimits(:,col),'--');  plot(t,maxLimits(:,col),'--');
   subplot(3,1,3); col=3;
   plot(t,trcLocal(:,col)); hold on; plot(t,minLimits(:,col),'--');  plot(t,maxLimits(:,col),'--');
   %} 
   %%      
   % Remove glitches of markers going across the boundary but not staying
   % long enough.
   idx=filterglitch(idx,ceil(0.33*200));

   %Refine idx by looking into fpVmag if fp is provided
   if ~isempty(fp)
       %Get v_y for this fp
       trial=struct('fp',fp);
       trial=Topics.interpolate(trial,trctable.Header);
       fp=trial.fp;
       fpchannels=fp.Properties.VariableNames;
       fpv=fp{:,contains(fpchannels,[fpname '_v'])};
       fpvmag=vecnorm(fpv,2,2);
       idxfp=(fpvmag>minVmag);
       
       % extend the intervals of fp 
       idx_intervals=splitLogical(idx | idxfp);
       for intervalIdx=1:numel(idx_intervals)
          if ~any(idx(idx_intervals{intervalIdx}) & idxfp(idx_intervals{intervalIdx}))
            idxfp(idx_intervals{intervalIdx})=0;
          end
       end
       idx=idxfp; 
   end

   fpnamesTbl.Forceplate(idx)=fpnames(i);  

              
end
   
   
end


 



function H = getTransform(corners)
% Compute the homogeneous transformation matrix between the corners tile
% frame to the pattern tile frame centered at the origin.
    p1=[2 3 0];
    p2=[-2 3 0];    
    p3=[-2 -3 0];
    p4=[2 -3 0];
    
    pattern=[p1' p2' p3' p4'];
    
    pattern_centroid=mean(pattern,2);
    corners_centroid=mean(corners,2);
    
    xi=pattern-repmat(pattern_centroid,1,4);
    yi=corners-repmat(corners_centroid,1,4);
    
    S=xi*yi';
    
    [U,~,V]=svd(S);
    L = eye(3);
    if det(U * V') < 0
        L(3, 3) = -1;
    end
    r = V * L * U';
    t = corners_centroid - r*pattern_centroid;        
    H=[r t; 0 0 0 1];    
    
end
