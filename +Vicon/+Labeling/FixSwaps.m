function allmarkers=FixSwaps(allmarkers,modelFile,swapintervals,varargin)
% allmarkers=FixSwaps(allmarkers,swapintervals)
% For the intervals that contain marker swaps evaluate the matches for
% marker trajectories at the end of the swap intervals to relabel the
% sections and fix marker swaps.
% swapintervals can be generated from Vicon.findSwaps.


p=inputParser();
p.addParameter('Verbose',0,@isnumeric);
p.addParameter('RelativeDistances',[]);
p.parse(varargin{:});
Verbose=p.Results.Verbose;
M=p.Results.RelativeDistances;

if isempty(M)    
   M=Vicon.Labeling.ComputeDistances(allmarkers);
end

[allnames,umarkers,unames,lmarkers,lnames]=Vicon.MarkerCategories(allmarkers);

startFrame=allmarkers.(allnames{1}).Header(1);
endFrame=allmarkers.(allnames{1}).Header(end);

% Unlabel swap interval so that we don't preserve faulty data
[allmarkers,newUmarkers]=Vicon.Labeling.UnlabelIntervals(allmarkers,swapintervals);

markers=fieldnames(swapintervals);
for markerIdx=1:numel(markers)
    marker=markers{markerIdx};    
    intervals=swapintervals.(marker);
    
    for intervalIdx=1:numel(intervals)
        interval=intervals{intervalIdx};        
        
        allnames=fieldnames(allmarkers);
        
        % If marker exists at interval(1) it is possible that it was fixed
        % in a previous iteration. abort.        
        isnanStruct=Topics.transform(@(x)(any(isnan(x(:,2:end)),2)),allmarkers);
        isnanTable=Topics.consolidate(isnanStruct); 
        isnanTable.Properties.VariableNames=['Header'; allnames];
        
        if ~isnanTable{isnanTable.Header==interval(2),marker}
            continue;
        end
        
        % If interval contains the first frame or last frame abort
        if ((interval(1)==startFrame) || (interval(2)==endFrame))
            continue;
        end
                        
        [direction]=SolveSwap(allmarkers,marker,interval,M);
        
        thisMarker=Topics.select(allmarkers,marker);
        if direction>0
            % Label next as marker and unlabel previous
            prevInterval=Vicon.extendIntervals(struct(marker,{{[interval(1)-1 interval(1)]}}),thisMarker);
            [allmarkers,newUnlabeledMarkers]=Vicon.Labeling.UnlabelIntervals(allmarkers,prevInterval);
            allmarkers=Topics.merge(allmarkers,newUnlabeledMarkers);
            
            if Verbose>0
                newUnlabeledNames=fieldnames(newUnlabeledMarkers);
                newUnlabeledName=newUnlabeledNames{1};
                fprintf('new %s <-(swap @%d-%d)-> %s\n',newUnlabeledName,interval(1),interval(2),marker);
            end
                
        elseif direction<0            
            % Label previous as marker and unlabel next
            nextInterval=Vicon.extendIntervals(struct(marker,{{[interval(2) interval(2)+1]}}),thisMarker);
            [allmarkers,newUnlabeledMarkers]=Vicon.Labeling.UnlabelIntervals(allmarkers,nextInterval);
            allmarkers=Topics.merge(allmarkers,newUnlabeledMarkers);                        
            
            if Verbose>0
                newUnlabeledNames=fieldnames(newUnlabeledMarkers);
                newUnlabeledName=newUnlabeledNames{1};
                fprintf('%s <-(swap @%d-%d)-> new %s\n',marker,interval(1),interval(2),newUnlabeledName);
            end
            
        else
            continue;
        end
                
        allmarkers=Vicon.GapFill(allmarkers,modelFile,'EnableShort',true,'EnableLong',false);
        
        umarker=newUnlabeledMarkers.(newUnlabeledName);
        if direction>0
            loc=umarker.Header(find(~isnan(umarker.x),1,'last'));
        else
            loc=umarker.Header(find(~isnan(umarker.x),1,'first'));
        end
        
        % Match ends using trajectory matching        
        matches=Vicon.Labeling.Match_Trajectory(allmarkers,loc,'IncludeLabeled',false);
        if ~isempty(matches)               
            allmarkers=Vicon.Labeling.Label(allmarkers,loc,matches,'Verbose',Verbose);
        end    
        allmarkers=Vicon.GapFill(allmarkers,modelFile,'EnableShort',true,'EnableLong',false);
                
    end
end

end


%% %%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [direction]=SolveSwap(allmarkers,markername,interval,M)
% For a marker swap interval for a given marker and a relative distance
% measure from a markerset determine if the marker is defined before or
% after the swap. direction: +1 forward, -1 backward, 0 uncertain.

[allnames,umarkers,unames,lmarkers,lnames]=Vicon.MarkerCategories(allmarkers);

prevFrame=Topics.cut(allmarkers,interval(1)-1,interval(1)-1);
nextFrame=Topics.cut(allmarkers,interval(2)+1,interval(2)+1);

idx=find(strcmp(markername,lnames));

groundTruthDistance=M(idx,:);
prevDistancesMatrix=Vicon.Labeling.ComputeDistances(prevFrame);
nextDistancesMatrix=Vicon.Labeling.ComputeDistances(nextFrame);

prev=prevDistancesMatrix(idx,:);
next=nextDistancesMatrix(idx,:);

dprev=abs(groundTruthDistance-prev);
dnext=abs(groundTruthDistance-next);

nanlocs=(isnan(dprev) | isnan(dnext));

p=mean(dprev(~nanlocs));
n=mean(dnext(~nanlocs));

if p>n && p/n>1.2
    direction=1;
elseif p<n && n/p>1.2
    direction=-1;
else
    direction=0;
end


end








