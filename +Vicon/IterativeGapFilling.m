function [markerData, errorTable, fillTime] = IterativeGapFilling(c3dFile, ikXml, varargin)
% IterativeGapFilling  Iteratively gap-fills marker data in c3d files
% [markerData, errorTable, fillTime] = IterativeGapFilling(c3dFile, ikXml, varargin)
%   In:
%       c3dFile - a single c3d file
%       ikXml - path to IK setup file .xml. Must reference correct osim
%         model file.
%   Optional Inputs:
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
%   See also: Vicon.GapFill, Vicon.GapMake.

validScalar=@(x) isnumeric(x) && isscalar(x);
p = inputParser;
p.addParameter('MaxIterations',2, validScalar);
p.addParameter('VerboseLevel',0, validScalar);
p.addParameter('ErrorThresholdLow', 0.04, validScalar);
p.addParameter('ErrorThresholdHigh', 0.06, validScalar);
p.parse(varargin{:});
verboseLevel = p.Results.VerboseLevel;
maxIterations = p.Results.MaxIterations;
ErrorThresholdLow = p.Results.ErrorThresholdLow;
ErrorThresholdHigh = p.Results.ErrorThresholdHigh;
scaledOsim = Osim.readTagFromXML(ikXml, 'model_file');

if ~exist(scaledOsim, 'file')
    % if scaledOsim is not found, then it is likely a relative path, so
    % search relative to the location of ikXml
    newScaledOsim = fullfile(fileparts(ikXml), scaledOsim);
    if ~exist(newScaledOsim, 'file')
        error(['Location of scaled .osim file could not be inferred ' ...
            'from IK .xml file. (Searched "%s" and "%s").'], ...
            scaledOsim, newScaledOsim);
    end
    scaledOsim = newScaledOsim;
end



fprintf('Beginning Gap Filling\n')

t = tic;
change = true;
iterations = 1;

fprintf('----------------------------------------\n')
[~,fileName] = fileparts(c3dFile);
fprintf('Gap filling file: %s\n',fileName)
markerDataWithGaps = Vicon.ExtractMarkers(c3dFile);
while (iterations <= maxIterations && change)
    fprintf('  Iteration: %i\n',iterations)
    
    fprintf('  Running GapFill\n')
    markerData = Vicon.GapFill(markerDataWithGaps, scaledOsim, 'VerboseLevel', verboseLevel);
    
    fprintf('  Running GapMake\n')
    [errorTable, markerDataWithGaps, change] = Vicon.GapMake(markerData, ikXml,...
        'ErrorThresholdLow',ErrorThresholdLow, ...
        'ErrorThresholdHigh',ErrorThresholdHigh,'VerboseLevel',verboseLevel);
    
    iterations = iterations + 1;
end
if change
    fprintf('  Iterations ended because number of iterations exceeded max iterations\n');
else
    fprintf('  Iterations ended because max error converged below thresholds!\n');
    markerData = markerDataWithGaps; % because it doesn't have any gaps
end
fillTime = toc(t);
end
