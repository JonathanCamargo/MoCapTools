function allMarkers=Label(allMarkers,frame,matches,varargin)
% function relabeledMarkers=Label(allMarkers,frameloc,matches,OPTIONAL)
% Label markers by assigning the labels (matches{i,2}) to the unlabel markers
% (matches{i,1}) for trajectories that contain a given frame.
% lmatches and umatches are cell vectors that contain the name of the label
% and unlabeled markers respectively.
% 
%       Verbose  - (0) minimal output, 1 normal, 2 debug mode
%

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('Verbose',0, validScalar);

p.parse(varargin{:});
Verbose = p.Results.Verbose;


%% Extract names for convenience
[allnames,umarkers,unames,lmarkers,lnames] = Vicon.MarkerCategories(allMarkers);

   for j=1:size(matches,1)
       match=matches(j,:);
       if (Verbose>1)
        fprintf('\t%s->%s @%1.2f\n',match{1},match{2},frame);
       end   
         %So, lets grab the data from the last gap up to the next gap of the upoint.
       udata=umarkers.(match{1});
       % Find previous gap and next gap of udata       
       a=isnan(udata{:,2:end});
       hasAll=~any(a,2);
       mask=udata.Header<frame;
       previousGapIdx=find(((~hasAll) & mask),1,'last');
       nextGapIdx=find(((~hasAll) & ~mask),1,'first');
       if isempty(nextGapIdx); nextGapIdx=numel(hasAll)+1; end
       if isempty(previousGapIdx); previousGapIdx=0; end

       ustart=udata.Header(previousGapIdx+1);
       uend=udata.Header(nextGapIdx-1);       
       a=Topics.cut(umarkers,ustart,uend,match(1));
       utable=a.(match{1});
       % Insert the unlabeled data into the labeled marker
       z=lmarkers.(match{2});
       z{previousGapIdx+1:nextGapIdx-1,:}=utable.Variables;
       lmarkers.(match{2})=z; 
       % Remove the unlabeled data from the unlabeled marker
       utable{:,2:end}=nan*utable{:,2:end};
       z=umarkers.(match{1});
       z{previousGapIdx+1:nextGapIdx-1,:}=utable.Variables;
       umarkers.(match{1})=z;       
       allMarkers=Topics.merge(lmarkers,umarkers);
   end
   



end

