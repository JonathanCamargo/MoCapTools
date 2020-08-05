function [allMarkers, errorTable] = IterativeGapFilling(c3dFile,varargin)
% IterativeGapFillingPuto  UNDER DEVELOPMENT - EXPERIMENTAL
% Iteratively gap-fills marker data in c3d files
% [markerData, errorTable, fillTime] = IterativeGapFilling(c3dFile, ikXml, varargin)
%   In:
%       c3dFile - a single c3d file
%
%   Optional Inputs (Name value pair):
%
%       VerboseLevel - 0 (minimal, default), 1 (normal), 2 (debug mode)
%
%       Enable different parts of the method by selecting true or false
%          CleanLabels (true)/false
%          FillGaps (true)/false
%          MakeGaps (true)/false
%
%       Each method has some additional configurable parameters:
%
%          CleanLabels:
%       ikXml - path to IK setup file .xml. Must reference correct osim
%         model file.
%
%       MaxIterations - number of iterations of gapFill/gapMake (default: 2)
%       VerboseLevel - 0 (minimal, default), 1 (normal), 2 (debug mode)
%       ErrorThresholdLow - threshold of IK error above which bad marker
%         data will be deleted. (default is 0.04)
%       ErrorThresholdHigh - threshold of IK error above which marker data
%         will be considered bad. (default is 0.06)
%
%   Out:
%       markerData, errorTable, and fillTime
%
%   See also: Vicon.GapFill, Vicon.GapMake, Vicon.Relabel


validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('VerboseLevel',0, validScalar);
%Methods to run
p.addParameter('CleanLabels',true,@islogical);
p.addParameter('FillGaps',true,@islogical);
p.addParameter('MakeGaps',true,@islogical);
% Method dependent parameters
% CleanLabels
p.addParameter('LabelingMaxIterations',5,@isnumeric);
% FillGaps
p.addParameter('IkXml','',@ischar);
p.addParameter('OsimFile','',@ischar);
% MakeGaps
p.addParameter('ErrorThresholdLow',40E-3,@isnumeric);
p.addParameter('ErrorThresholdHigh',60E-3,@isnumeric);

% Iterative filling
p.addParameter('MaxIterations',4,@isnumeric);
p.addParameter('AbortOnHighError',true,@islogical);

p.parse(varargin{:});
VerboseLevel = p.Results.VerboseLevel;

CleanLabels = p.Results.CleanLabels;
FillGaps = p.Results.FillGaps;
MakeGaps = p.Results.MakeGaps;

% CleanLabels
LABELINGMAXITERATIONS=p.Results.LabelingMaxIterations;

% FillGaps
IkXml=p.Results.IkXml;
OsimFile=p.Results.OsimFile;

% MakeGaps
ErrorThresholdLow=p.Results.ErrorThresholdLow;
ErrorThresholdHigh=p.Results.ErrorThresholdHigh;

% Iterative
MaxIterations=p.Results.MaxIterations;
AbortOnHighError=p.Results.AbortOnHighError;




% Load markers
if ischar(c3dFile)
    allMarkers=Vicon.ExtractMarkers(c3dFile); % MarkerData with all the markers
elseif isstruct(c3dFile)
    allMarkers=c3dFile;
end
    

errorTable=[]; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Revisiting Iterative gap filling algorithm including label data preservation
% This version prevents missing information due to bad labeling. Coded when
% listening to the TNT BAND. "Sabré olvidar, sabré olvidar...".
% Steps of the algorithm

% CLEANGAPS
% 1. Smooth the marker data to determine regions with possible labeling
% errors. Unlabel those regions in the original data.
% 2. Attempt relabeling until convergence (or max iterations) on some of
% the frames that are candidate for relabel.
% FILL GAPS
% 3. Use GapFill to fill in the gaps on this better initial labeled data.
% MAKE GAPS
% 4. Run  Inverse kinematics on the entire thing and determine sections
% with high errors.
% Iterate over those sections with GapMake and GapFill until maxout iters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Find gaps and sort them
% gaps=Vicon.findGaps(allMarkers); %USe this table to see how bad are the gaps

%% CLEAN LABELS
if (CleanLabels)
    fprintf('Cleaning labels\n');
    % 1. Generate a smooth version of the marker data to determine sections with errors

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

    intervals=Topics.findTimes(@(x)(x.Distance>(4*std(x.Distance)+mean(x.Distance))),difference,labeledMarkerNames);
    [cleanedMarkers, newUnlabeledMarkers]=Vicon.unlabelIntervals(allMarkers,intervals);
    allMarkers=Topics.merge(cleanedMarkers,newUnlabeledMarkers);

    if (VerboseLevel==1)
        a=struct2cell(intervals);
        a=vertcat(a{:});a=vertcat(a{:}); a=sort(a,1);
        numframes=sum((a(:,2)-a(:,1))+1);
        if ~isempty(a)
            numframes=sum((a(:,2)-a(:,1))+1);
        else
            numframes=0;
        end
        fprintf('Unlabeled %d frames\n',numframes);
        names=fieldnames(intervals);
        for i=1:numel(names)
            a=vertcat(intervals.(names{i}){:});        
            if isempty(a); continue; end            
            fprintf('\t%s %d\n',names{i},sum(1+(a(:,2)-a(:,1))));
        end
    elseif (VerboseLevel==2)
        a=struct2cell(intervals);
        a=vertcat(a{:});a=vertcat(a{:}); a=sort(a,1);
        if ~isempty(a)
            numframes=sum((a(:,2)-a(:,1))+1);
        else
            numframes=0;
        end
        fprintf('Unlabeled %d frames\n',numframes);
        names=fieldnames(intervals);
        for i=1:numel(names)
            a=vertcat(intervals.(names{i}){:});        
            if isempty(a); continue; end            
            fprintf('\t%s (%d)\n',names{i},sum(1+(a(:,2)-a(:,1))));
            fprintf('\t\t%1.2f - %1.2f\n',a');
        end
    end

    % Use unlable to split the data from unlabled markers on points with high velocity
    [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
    
    if ~isempty(unlabeledMarkerNames)
        intervals=Topics.findTimes(@HighVelocityCondition,unlabeledMarkers,unlabeledMarkerNames);
        [cleanedMarkers,newUnlabeledMarkers]=Vicon.unlabelIntervals(allMarkers,intervals);
        allMarkers=Topics.merge(cleanedMarkers,newUnlabeledMarkers);

        % Save the output to check
        % Vicon.markerstoC3D(allMarkers,c3dFile,tempC3DFile);

        % 2. Use relable to see if those new unlabled markers can be used

        [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
            ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);

        change=true; lastNumSections=inf;    
        if (VerboseLevel>0)
            fprintf('Relabeling\n');
        end
        for iters=1:LABELINGMAXITERATIONS    
            if change==false
                break;
            end

            if (VerboseLevel==2)
                fprintf('\tIteration %d\n',iters);
            end

            % For places with gaps try to check if there are unlabeled markers that could be labeled markers.
            [tentativeSections,tentativeSectionSize]=getTentativeSections(allMarkers);
            [sortedVals,sortedIdx]=sort(tentativeSectionSize,'descend');
            sortedSections=tentativeSections(sortedIdx(sortedVals>mean(sortedVals)));

            for i=1:numel(sortedSections)
                targetFrame=tentativeSections{i}(1);
                segment=Topics.cut(allMarkers,targetFrame-150,targetFrame+150,allMarkerNames);    
                out=Vicon.Relabel(segment,targetFrame,'VerboseLevel',VerboseLevel);
                % Copy segment to the allMarkers set
                allMarkers=Topics.merge(allMarkers,out);
            end

            if numel(sortedSections)<lastNumSections
                lastNumSections=numel(sortedSections);
            else
                change=false;
            end        
        end
        % Save the output to check
        % Vicon.markerstoC3D(allMarkers,c3dFile,tempC3DFile);
    end
end

%% Iterative process
if (FillGaps)    
    [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
    fprintf('Filling gaps\n');
    EnableLong=true;
    if (isempty(OsimFile))
        if (~isempty(IkXml))
            xmlObj = xmlread(IkXml);
            OsimFile = xmlObj.getElementsByTagName('model_file').item(0).getTextContent.toCharArray';                    
            if ~exist(OsimFile, 'file')
                % if OsimFile is not found, then it is likely a relative path, so
                % search relative to the location of IkXml
                newOsim = fullfile(fileparts(IkXml), OsimFile);
                if ~exist(newOsim, 'file')
                    error(['Location of scaled .osim file could not be inferred ' ...
                        'from IK .xml file. (Searched "%s" and "%s").'], ...
                        OsimFile, newOsim);
                end
                OsimFile = newOsim;
            end
        else
            EnableLong=false;        
        end
    end
end

change=true;
iters=0;
while (change && iters<MaxIterations) 
    iters=iters+1;                                
    if (FillGaps)
        % Fill gaps
        fprintf('\tIteration %d\n',iters);
        filled=Vicon.GapFill(allMarkers,OsimFile,'VerboseLevel',VerboseLevel,'EnableLong',EnableLong);
        allMarkers=Topics.merge(allMarkers,filled);
    end
    
    if (MakeGaps)
        % Make gaps
        fprintf('Making gaps\n');
        [errorTable, markerData, intervals] = Vicon.GapMake(allMarkers, IkXml, 'ErrorThresholdLow',ErrorThresholdLow,'ErrorThresholdHigh',ErrorThresholdHigh);
        err=mean(errorTable{:,2:end}); stderr=std(errorTable{:,2:end});

        %Evaluate errorTable to determine if it is worth to keep going
        if any(err>ErrorThresholdHigh)
            fprintf('mean error > %1.2f (mm) for:\n',ErrorThresholdHigh*1000);
            markerNames=errorTable.Properties.VariableNames(2:end);
            errMarkerNames=markerNames(err>ErrorThresholdHigh);
            for i=1:numel(errMarkerNames)
                fprintf('\t%s\n',errMarkerNames{i});
            end    
            if AbortOnHighError
                    error('Errors are excesive, aborting process. Please check the static and improve the markers in the model');                
            else
                    warning('Errors are excesive. Please check the static and improve the markers in the model');                                
                    break;
            end        
        end   

        %will just work with this section until finished.
        a=struct2cell(intervals); a=vertcat(a{:});
        thisIntervals=vertcat(a{:}); 
        if isempty(thisIntervals)
            change=false;
            fprintf('Finished this section\n');
            break;
        end

        % Here I should save the last gapmade section and add it to the
        % allMarker    
        nanTable=allMarkers.(allMarkerNames{1}); nanTable{:,2:end}=nan;
        newMarkerNames=setdiff(fieldnames(markerData),fieldnames(allMarkers));
        if ~isempty(newMarkerNames)
            placeHolder=Topics.processTopics(@(x)(nanTable),filled,newMarkerNames);
            allMarkers=Topics.merge(placeHolder,allMarkers);
        end
        allMarkers=Topics.merge(allMarkers,markerData);
        %No need to keep spliting the file and branch out more sections so I       
    end
end

        
if (change==true)
    fprintf('Iterations maxed out\n');
else    
    % Here I should save the last filled section and add it to the
    % allMarker    
    nanTable=allMarkers.(allMarkerNames{1}); nanTable{:,2:end}=nan;
    newMarkerNames=setdiff(fieldnames(filled),fieldnames(allMarkers));
    if ~isempty(newMarkerNames)
        placeHolder=Topics.processTopics(@(x)(nanTable),filled,newMarkerNames);
        allMarkers=Topics.merge(placeHolder,allMarkers);
    end
    allMarkers=Topics.merge(allMarkers,filled);
end

    

fprintf('Iterative gap filling ended\n');

%% Final call to makeGaps to generate the final error table after iterative
if (MakeGaps)
    fprintf('Making gaps\n');
    [errorTable, ~, ~,~] = Vicon.GapMake(allMarkers, IkXml, 'ErrorThresholdLow',ErrorThresholdLow,'ErrorThresholdHigh',ErrorThresholdHigh);
    err=mean(errorTable{:,2:end}); stderr=std(errorTable{:,2:end});

    %Evaluate errorTable to determine if it is worth to keep going
    if any(err>ErrorThresholdHigh)
        fprintf('mean error > %1.2f (mm) for:\n',ErrorThresholdHigh*1000);
        markerNames=errorTable.Properties.VariableNames(2:end);
        errMarkerNames=markerNames(err>ErrorThresholdHigh);
        for i=1:numel(errMarkerNames)
            fprintf('\t%s\n',errMarkerNames{i});
        end    
        if AbortOnHighError
                error('Errors are excesive, aborting process. Please check the static and improve the markers in the model');                
        else
                warning('Errors are excesive. Please check the static and improve the markers in the model');                                
        end        
    end   
end


end





%% %%%%%%%%%%%%%%%%%%%%% HELPER FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers)
% From a full marker dataset split in unlabeled and labeled
    allMarkerNames=fieldnames(allMarkers);
    unlabeledMarkerNames=allMarkerNames(contains(allMarkerNames,'C_'));
    labeledMarkerNames=setdiff(allMarkerNames,unlabeledMarkerNames);
    if ~isempty(unlabeledMarkerNames)
        unlabeledMarkers=Topics.select(allMarkers,unlabeledMarkerNames);
    else
        unlabeledMarkers=struct();
    end
    labeledMarkers=Topics.select(allMarkers,labeledMarkerNames);
end

function [tentativeSections,tentativeSectionSize]=getTentativeSections(allMarkers)
    % Determine tentative sections for relabeling. i.e. Frames where change
    % in markers exist and there are unlabeled markers.
    [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames...
        ,labeledMarkers,labeledMarkerNames] = getMarkerCategories(allMarkers);
    if isempty(unlabeledMarkerNames)
        tentativeSections=struct();
        tentativeSectionSize=struct();
        return;
    end
    % Run a fast labeling to check for missing labels first
    % Go forward from the first frame with all markers
    lmarkers=Topics.consolidate(labeledMarkers,labeledMarkerNames,'Prepend',true);
    umarkers=Topics.consolidate(unlabeledMarkers,unlabeledMarkerNames,'Prepend',true);
    header=lmarkers.Header;
    frameHasAll=all(~isnan(lmarkers{:,2:end}),2);
    frameHasUnlabeled=any(~isnan(umarkers{:,2:end}),2);
    isTentativeFrame= (~frameHasAll & frameHasUnlabeled);
    % Determine where there are changes in the markers and target those frames
    % to make the process more efficient.
    tentativeSections=splitLogical(isTentativeFrame);
    tentativeSections=cellfun(@(x)(header(x)),tentativeSections,'Uni',0);
    tentativeSectionSize=cellfun(@numel,tentativeSections);
    %[sortedVals,sortedIdx]=sort(tentativeSectionSize,'descend');
    %tentativeSections=tentativeSections(sortedIdx(sortedVals>mean(sortedVals)));
end















































