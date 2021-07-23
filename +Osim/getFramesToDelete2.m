function [markers, frames] = getFramesToDelete2(errorTable)
% UNDER DEVELOPMENT
% For a force plate data set and an error table for a single trial, return
% the markers that have high error in important regions of the trial, and
% the frames in which those errors occur.
% [markers, frames] = getFramesToDelete(errorTable, lowThresh, highThresh, FPFile)
% [markers, frames] = getFramesToDelete(errorTable, lowThresh, highThresh)
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
    
    x=errorTable{:,2:end};
    x(isnan(x))=0;
    rmserror=rms(rms(x));
    maxrmserror=max(max(x));
    errorratio=maxrmserror/rmserror;
    x(x<rmserror*errorratio*0.9)=rmserror;
    % Saturated error surface
    y=x;
    y(y<rmserror*errorratio*0.9)=0; %To keep
    y(y>rmserror*errorratio*0.9)=1; %To delete
    [frameidx,markeridx]=find(imregionalmax(y));
    
    markerNames=errorTable.Properties.VariableNames(2:end);
    unique_markeridx=unique(markeridx);
    markers={}; frames={};
    for i=1:numel(unique_markeridx)
        markerFrames=frameidx(markeridx==unique_markeridx(i));        
        markers=[markers; markerNames(unique_markeridx(i))];
        frames=[frames,markerFrames];
    end    
end