function allMarkers = CleanLabels(allMarkers,varargin)
% allMarkers = CleanLabels(allMarkers,varargin)
% For a marker structure clean the marker labels by using the following steps:
%
%  1. Generate a smooth version of the marker data to determine sections with errors
%  2. Use relable to see if those new unlabled markers can be used as labeled markers
%  3. Relable frames that are not in gaps but can potentially be labeled    
%  Iterate between 2 and 3 for a given number of iterations.
%
%  Options:
%       VerboseLevel  - (0) minimal output, 1 normal, 2 debug mode
%       MaxIterations - (2) Iterations of the clean labels algorithm

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('VerboseLevel',0, validScalar);
p.addParameter('MaxIterations',2,@isnumeric);
p.addParameter('StartAndEndMaxIterations',nan,@isnumeric);
p.addParameter('GapMaxIterations',nan,@isnumeric);
p.parse(varargin{:});
VerboseLevel = p.Results.VerboseLevel;

LABELINGMAXITERATIONS=p.Results.MaxIterations;
GAPLABELINGMAXITERATIONS=p.Results.GapMaxIterations;
STARTANDENDLABELINGMAXITERATIONS=p.Results.StartAndEndMaxIterations;
if isnan(GAPLABELINGMAXITERATIONS); GAPLABELINGMAXITERATIONS=LABELINGMAXITERATIONS; end
if isnan(STARTANDENDLABELINGMAXITERATIONS); STARTANDENDLABELINGMAXITERATIONS=LABELINGMAXITERATIONS; end

% 1. Generate a smooth version of the marker data to determine sections with errors
    if (VerboseLevel>0)
            fprintf('STEP 1. Eliminate labels that are not good\n');
    end
    [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);

    SMOOTHINGWINDOW=80;
    header=allMarkers.(allMarkerNames{1}).Header;
    fun=@(x)(x(~isnan(x{:,2}),:));
    removedNans=Topics.processTopics(fun,labeledMarkers,labeledMarkerNames);
    % Remove markers that appear for less than 10% of the frames     
    numFrames=Topics.processTopics(@height,removedNans,labeledMarkerNames);
    markersToRemove=labeledMarkerNames(struct2array(numFrames)<0.1*max(struct2array(numFrames)));
    if ~isempty(markersToRemove)
        warning_msg=fprintf('Removing markers with less than 10%% of frames\n');
        warning_msg=[warning_msg sprintf('\t%s\n',markersToRemove{:})];
        warning(warning_msg);
        allMarkers=Topics.remove(allMarkers,markersToRemove);
        labeledMarkerNames=setdiff(labeledMarkerNames,markersToRemove);
        removedNans=Topics.remove(removedNans,markersToRemove);    
    end
    interpolated=Topics.interpolate(removedNans,header,labeledMarkerNames);
    fun=@(x)([smooth(x(:,1),SMOOTHINGWINDOW), smooth(x(:,2),SMOOTHINGWINDOW), smooth(x(:,3),SMOOTHINGWINDOW)]);
    smoothed=Topics.transform(fun,interpolated,labeledMarkerNames);

    % Find where there is difference between the smoothed and the interpolated
    difference=struct();
    for i=1:numel(labeledMarkerNames)
        x1=interpolated.(labeledMarkerNames{i});
        x2=smoothed.(labeledMarkerNames{i});
        a=vecnorm((x1{:,2:end}-x2{:,2:end}),2,2);
        difference.(labeledMarkerNames{i})=array2table([x1.Header,a],'VariableNames',{'Header','Distance'});
    end

    intervals1=Topics.findTimes(@(x)(x.Distance>(4*std(x.Distance)+mean(x.Distance))),difference,labeledMarkerNames);
    
    fun=@(x)filterglitch((HighVelocityCondition(x) & HighAccelerationCondition(x)),60);
    intervals2=Topics.findTimes(fun,labeledMarkers,labeledMarkerNames);
        
    [cleanedMarkers, newUnlabeledMarkers]=Vicon.unlabelIntervals(allMarkers,intervals1);
    allMarkers=Topics.merge(cleanedMarkers,newUnlabeledMarkers);
    
    [cleanedMarkers, newUnlabeledMarkers]=Vicon.unlabelIntervals(allMarkers,intervals2);
    allMarkers=Topics.merge(cleanedMarkers,newUnlabeledMarkers);


    a=[struct2cell(intervals2);struct2cell(intervals2)];
    a=vertcat(a{:});a=vertcat(a{:}); a=sort(a,1);
    
    if ~isempty(a)
    names=fieldnames(intervals1);
        for i=1:numel(names)
            a=vertcat(intervals1.(names{i}){:});        
            if isempty(a); continue; end       
                if (VerboseLevel==1) 
                    fprintf('\t%s %d\n',names{i},sum(1+(a(:,2)-a(:,1))));
                elseif (VerboseLevel==2)
                    fprintf('\t%s (%d)\n',names{i},sum(1+(a(:,2)-a(:,1))));
                    fprintf('\t\t%1.2f - %1.2f\n',a');
                end        
        end
    end

    % Use unlable to split the data from unlabled markers on points with high velocity
    [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
    if ~isempty(unlabeledMarkerNames)
        intervals=Topics.findTimes(@HighVelocityCondition,unlabeledMarkers,unlabeledMarkerNames);
        [cleanedMarkers,newUnlabeledMarkers]=Vicon.unlabelIntervals(allMarkers,intervals);
        allMarkers=Topics.merge(cleanedMarkers,newUnlabeledMarkers);
    end
    % Save the output to check
    % Vicon.markerstoC3D(allMarkers,c3dFile,tempC3DFile);

      
    for itersHigh=1:LABELINGMAXITERATIONS
        % 2. Use relable to see if those new unlabled markers can be used
        change=true; lastMeanLength=inf; 
       [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
       ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
        if (VerboseLevel>0)
            fprintf('STEP %d. Relabeling\n',itersHigh+1);
        end
        if numel(unlabeledMarkerNames)==0
            fprintf('No unlabeledMarkers, skipping/n');
            return;
        end

        for iters=1:GAPLABELINGMAXITERATIONS    
            if change==false
                break;
            end

            if (VerboseLevel==2)
                fprintf('\tGap labeling. Iteration %d\n',iters);
            end

            % For markers with the longest gaps check if it is possible to
            % relable at the start of the gap.
            [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
            ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
            gapTable=genGapTable(labeledMarkers);       
            if isempty(gapTable); change=false; break; end
            
            
                      
            gapTable=sortrows(gapTable,'Length','descend');
            [~,loc]=unique(gapTable.Start,'stable');
            gapTable=gapTable(loc,:);
            %For the biggest gaps attempt to relable first
            biggestGaps=gapTable(gapTable.Length>mean(gapTable.Length),:);
            
            %Check start and end of gap and remove or modify gaps that
            %would not be relabeled due to lack of unlabeledMarkers in that
            %frame.
            umarkers=Topics.consolidate(unlabeledMarkers,unlabeledMarkerNames,'Prepend',true);
            hasNaN=isnan(umarkers{:,2:end});
            frameHasUnlabeledMarkers=~all(hasNaN,2);
            framesWithUnlabeledMarkers=umarkers.Header(1)+find(frameHasUnlabeledMarkers)-1;

            ignoreThisGap=false(height(biggestGaps),1);
            for i=1:height(biggestGaps)
                cond1=biggestGaps.Length(i)>3;
                cond2=isempty(find(framesWithUnlabeledMarkers==biggestGaps.Start(i)+1,1));
                ignoreThisGap(i)=false;
                if ( cond1 && cond2)                    
                    next1=biggestGaps.Start(i)+2;
                    next2=biggestGaps.Start(i)+3;
                    next3=biggestGaps.Start(i)+4;
                    condNext1=find(framesWithUnlabeledMarkers==next1);
                    condNext2=find(framesWithUnlabeledMarkers==next2);
                    condNext3=find(framesWithUnlabeledMarkers==next3);
                    if (condNext1)
                        biggestGaps.Start(i)=next1; %Check Next frame
                    elseif (condNext2)
                        biggestGaps.Start(i)=next2; %Check Next frame
                    elseif (condNext3)
                        biggestGaps.Start(i)=next3; %Check Next frame
                    else
                        ignoreThisGap(i)=true;
                    end
                else
                    ignoreThisGap(i)=true;
                end
               
                cond2=isempty(find(framesWithUnlabeledMarkers==biggestGaps.End(i)-1,1));
                if ( cond1 && cond2)                    
                    prev1=biggestGaps.End(i)-2;
                    prev2=biggestGaps.End(i)-3;
                    prev3=biggestGaps.End(i)-4;
                    condPrev1=find(framesWithUnlabeledMarkers==prev1);
                    condPrev2=find(framesWithUnlabeledMarkers==prev2);
                    condPrev3=find(framesWithUnlabeledMarkers==prev3);
                    if (condPrev1)
                        biggestGaps.End(i)=prev1; %Check Previous frame
                    elseif (condPrev2)
                        biggestGaps.End(i)=prev2; %Check Previous frame
                    elseif (condPrev3)
                        biggestGaps.End(i)=prev3; %Check Previous frame
                    else
                        ignoreThisGap(i)=true;
                    end
                else
                    ignoreThisGap(i)=true;
                end                                                                      
            end    
            biggestGaps=biggestGaps(~ignoreThisGap,:);

            if height(biggestGaps)==0
                fprintf('\t\tNo gaps worth to Relabel\n');
                break;
            end
                
            %Label forward in gap (seed is start of gap)
            for i=1:height(biggestGaps)
               targetFrame=biggestGaps.Start(i)+1;
               %Maybe just attempt to label only the marker?
               fprintf('Labeling @%d/n',targetFrame)
               segment=Topics.cut(allMarkers,targetFrame-150,targetFrame+150,allMarkerNames);               
               [out,wasRelabeled]=Vicon.Relabel(segment,targetFrame,'VerboseLevel',VerboseLevel);
               % Copy segment to the allMarkers set
               allMarkers=Topics.merge(allMarkers,out);            
            end

            %Label backward in gap (seed is end of gap)
            for i=1:height(biggestGaps)
               targetFrame=biggestGaps.End(i)-1;               
               fprintf('Labeling @%d/n',targetFrame)
               %Maybe just attempt to label only the marker?
               segment=Topics.cut(allMarkers,targetFrame-150,targetFrame+150,allMarkerNames);     
               [out,wasRelabeled]=Vicon.Relabel(segment,targetFrame,'VerboseLevel',VerboseLevel);              
               % Copy segment to the allMarkers set
               allMarkers=Topics.merge(allMarkers,out);            
            end

            %Find the biggest gaps again to check if it is worth to keep going
            [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
            ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);        
            gapTable=genGapTable(labeledMarkers);       
            if isempty(gapTable)
                break;
            end
            gapTable=sortrows(gapTable,'Length','descend');

            [~,loc]=unique(gapTable.Start,'stable');
            gapTable=gapTable(loc,:);        
            biggestGaps=gapTable(gapTable.Length>mean(gapTable.Length),:);
            if mean(biggestGaps.Length)<lastMeanLength
                lastMeanLength=mean(biggestGaps.Length);
            else
                change=false;
            end        
        end
        changeGapLabel=change;
        % Save the output to check
        % Vicon.markerstoC3D(allMarkers,c3dFile,tempC3DFile);

        % 3. Relable frames that are not in gaps but can potentially be labeled    
        for iters=1:STARTANDENDLABELINGMAXITERATIONS    
            if (VerboseLevel==2)
                fprintf('\tStart and end labeling. Iteration %d\n',iters);
            end
            change=false;
            [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
            ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers); 

            % Check if first block of frames are not labeled and label backwards
            lmarkers=Topics.consolidate(labeledMarkers,labeledMarkerNames,'Prepend',true);
            % This means that first section needs relabel (this was not addresed by gap relabeling since it is not a GAP)
            hasNaN=isnan(lmarkers{:,2:end});
            
            % Label at the start by finding a good tentative frame that is
            % not gap.
            skip=false; changeStart=false;      
            if all(hasNaN(1,:))                        
                firstLabeledFrameIdx=find(~all(hasNaN,2),1);                
            else
                % Try to get a frame where we change from very few labels
                % to multiple labels.
                a=diff(sum(hasNaN,2)); a(a>0)=0; a=a*-1;
                [pkval,pkIdx]=findpeaks(a,'MinPeakProminence',10);
                [sortedPkval,sortedIdx]=sort(pkval,'descend');
                sortedPkIdx=pkIdx(sortedIdx);
                if numel(sortedPkval)<1
                    skip=true;
                    firstLabeledFrameIdx=1;
                else
                    firstLabeledFrameIdx=sortedPkIdx(1);
                end                
            end
            if ~skip
                targetFrame=firstLabeledFrameIdx-1+lmarkers.Header(1);
                if (targetFrame<1000)
                    startFrame=lmarkers.Header(1);
                else
                    startFrame=targetFrame-150;
                end
                segment=Topics.cut(allMarkers,startFrame,targetFrame+150,allMarkerNames);               
                [out,changeStart]=Vicon.Relabel(segment,targetFrame,'VerboseLevel',VerboseLevel);
                % Copy segment to the allMarkers set
                allMarkers=Topics.merge(allMarkers,out);             
            end
            
            % Check if last block of frames are not labeled and label forward
            skip=false; changeEnd=false;
            if all(hasNaN(end,:))
                lastLabeledFrameIdx=find(~all(hasNaN,2),1,'last');
            else                     
                % Try to get a frame where we change from very few labels
                % to multiple labels.
                a=diff(sum(hasNaN,2)); a(a<0)=0;
                [pkval,pkIdx]=findpeaks(a,'MinPeakProminence',10);
                [sortedPkval,sortedIdx]=sort(pkval,'descend');     
                sortedPkIdx=pkIdx(sortedIdx);
                if numel(sortedPkval)<1
                    skip=true;
                    lastLabeledFrameIdx=1;
                else                    
                    lastLabeledFrameIdx=sortedPkIdx(1);                    
                end                
            end      
            if ~skip                
                targetFrame=lastLabeledFrameIdx+lmarkers.Header(1);            
                if (targetFrame>(numel(lmarkers.Header)-1000))
                    endFrame=lmarkers.Header(end);
                else
                    endFrame=targetFrame+150;
                end
                segment=Topics.cut(allMarkers,targetFrame-150,endFrame,allMarkerNames);               
                [out,changeEnd]=Vicon.Relabel(segment,targetFrame,'VerboseLevel',VerboseLevel);
                % Copy segment to the allMarkers set
                allMarkers=Topics.merge(allMarkers,out);  
            end
            change=( changeStart || changeEnd);        
            if change==false; break; end        
        end    
        changeStartEnd=change;
        
        if (~changeGapLabel && ~changeStartEnd)
            break;
        end
            
    end

end
   