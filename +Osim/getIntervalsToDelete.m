function [lowThreshIntervals, highThreshIntervals] = getIntervalsToDelete(errorTable, lowThresh, highThresh, FPFile)
% For a force plate data set and an error table for a single trial, return
% the markers that have high error in important regions of the trial, and
% the frames in which those errors occur.
% [lowThreshIntervals, highThreshIntervals] = getIntervalsToDelete(errorTable, lowThresh, highThresh, FPFile)
% [markers, frames] = getIntervalsToDelete(errorTable, lowThresh, highThresh)
% errorTable should be a table of inverse kinematics marker errors outputted
% from Osim.IK. If FPFile is not provided, then it will be assumed that the
% entire trial is relevant. 

    % any region where the error exceeds lowThresh will be flagged as high,
    % but only those regions where the error ever exceeds highThresh will
    % actually be deleted. So if the error exceeds lowThresh but not
    % highThresh, nothing will happen in that region. If the error exceeds
    % both, then the entire region exceeding lowThresh will be marked for
    % deletion. 
    narginchk(1, 4);
    if ~exist('lowThresh', 'var')
        lowThresh = 0.04;
    end
    if ~exist('highThresh', 'var')
        highThresh = 0.06;
    end
    
    % Find the locations where the markers error as a structure containing
    % marker names as fieldnames and the frames where they have high erorrs
    % as the values.
    % markerLocations = errorRange(errorTable, lowThresh, highThresh);
    
    % Transform the error table into Topics structure
    errorStruct=struct();
    markerNames=errorTable.Properties.VariableNames(2:end);
    for i=1:numel(markerNames)
        errorStruct.(markerNames{i})=array2table([errorTable.Header, errorTable.(markerNames{i})],...
            'VariableNames',{'Header','Error'});        
    end
    if ~exist('FPFile', 'var')
        locations = true(1, height(errorTable));
    else
        % Find the locations where we care about as a logical vector.
        locations = identifyRegionsOfInterest(FPFile);
    end
    % if any part of a high error region falls within the locations we care
    % about, mark the entire region of error to be removed so that gaps
    % will be interpolated from good data. 
    low=Topics.findTimes(@(x)(x.Error>lowThresh),errorStruct,fieldnames(errorStruct));
    high=Topics.findTimes(@(x)(x.Error>highThresh),errorStruct,fieldnames(errorStruct));
    
    
    for i=1:numel(markerNames)
       %For each marker check if a low interval contains a high interval
       % also discard intervals outside roi.
       highIntervals=high.(markerNames{i});
       lowIntervals=cell2mat(low.(markerNames{i}));       
       % Expand the low interval by one frame to compensate for filtering
       % effects in IK.    
       if ~isempty(lowIntervals)
        low.(markerNames{i})=mat2cell([lowIntervals(:,1)-1 lowIntervals(:,2)+1],ones(1,size(lowIntervals,1)),2);
       end
       lowerAdded=false(size(lowIntervals,1),1);
       for j=1:numel(highIntervals)
           lowerbound=highIntervals{j}(2)<= lowIntervals(:,2);
           upperbound=highIntervals{j}(1)>= lowIntervals(:,1);
           lowerAdded((lowerbound & upperbound))=true;
       end
       low.(markerNames{i})=low.(markerNames{i})(lowerAdded); % Only add lowIntervals that have higher threshold within    
       % Combine overlapping lows 
       if isempty(lowerAdded); continue; end
       a=cell2mat(low.(markerNames{i}));
       if size(a,1)>1
           toMerge=logical([0;(a(1:end-1,2)>=a(2:end,1))]);
           a(toMerge,1)=nan;
           for j=size(a,1):-1:2
              if isnan(a(j,1))
                  a(j-1,2)=a(j,2);
              end
           end
           a=a(~any(isnan(a),2),:);
           low.(markerNames{i})=mat2cell(a,ones(size(a,1),1),2);              
       end
    end
    lowThreshIntervals=low;
    highThreshIntervals=high;
    
    
    
end
