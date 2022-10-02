function sides = correlateForcePlates(trcTable, fpTable,varargin)
% Determines which force plate acts on which feet by looking for the heel
% closest to the point of action of a force on the first application of a
% force for each force plate. 
% Usage [SIDES] = correlateForcePlates(TRC_TABLE, FP_TABLE), where:
% TRC_TABLE is a table containing all the information from a .trc file. 
% FP_TABLE is a table containing all the information from a .mot file. 
% SIDES is a character vector containing 'r' or 'l' for each character, and
% the index corresponds to that force plate, in order that they appear in
% the GRF file (ex. 'lrrrl' means the 1st and 5th force plates that appear
% in the GRF file act on the left foot, and the other force plates act on
% the right foot).
% Optional Name-value pairs:
% 'LeftMarkers', cell array of L foot markers e.g }{'L_Heel','L_Toe_Tip'}
% 'RightMarkers', cell array of R foot markers}{'L_Heel','L_Toe_Tip'}
% 

p=inputParser();
p.addParameter('LeftMarkers',{'L_Heel','L_Toe_Tip'},@iscell);
p.addParameter('RightMarkers',{'R_Heel','R_Toe_Tip'},@iscell);
p.parse(varargin{:});
LeftMarkers=p.Results.LeftMarkers;
RightMarkers=p.Results.RightMarkers;


%% update trc and fp to have same time scale
fpTable = Osim.interpret(fpTable, 'MOT');
trcTable = Osim.interpret(trcTable, 'TRC');
trialData.FP = fpTable;
trialData.TRC = trcTable;
trialData = Topics.interpolate(trialData, trialData.TRC.Header, {'FP'});
fpTable = trialData.FP;

%% Get Marker Data
    % which marker do we want to use as representing the position of the
    % foot when comparing to force plate data
    %footIdentityMarker = 'Heel';
    % get columns with that marker
    %footCols = contains(trcTable.Properties.VariableNames, {footIdentityMarker, 'Header'});
    
    
    trc = table();
    trc.Header = trcTable.Header;
    trc.Left=zeros(height(trc),1);trc.Right=zeros(height(trc),1);
    for i=1:numel(LeftMarkers)
        LeftMarker=LeftMarkers{i};
        trc.Left = trc.Left+trcTable{:, compose([LeftMarker '_%c'], 'xyz')}/1000;
    end
    trc.Left=trc.Left/numel(LeftMarkers);
    
    for i=1:numel(RightMarkers)
        RightMarker=RightMarkers{i};
        trc.Right = trc.Right+trcTable{:, compose([RightMarker '_%c'], 'xyz')}/1000;
    end
    trc.Right=trc.Right/numel(RightMarkers);
    
        
    %% Get Force Data 
    % get all vertical forces and points of action
    threshold = 100;
    yForces = fpTable(:, contains(fpTable.Properties.VariableNames, {'_vy', 'Header'}));
    pressed = array2table(yForces{:, 2:end} > threshold);
    pressed.Header = yForces.Header;
    pressed = pressed(:, [end, 1:end-1]);
    pressed.Properties.VariableNames = strrep(yForces.Properties.VariableNames, '_vy', '');
    cop = fpTable(:, contains(fpTable.Properties.VariableNames, {'_p', 'Header'}));
    cop.Properties.VariableNames = strrep(cop.Properties.VariableNames, '_px', '_x');
    cop = Osim.table2markers(cop);
    % get names of force plates
    forcePlates = fieldnames(cop);
    %% Calculate closest foot for each force plate
    nForcePlates = length(forcePlates); %number of force plates
    sides = repmat('r', 1, nForcePlates); %initialize with all right side
    
    for idx = 1:nForcePlates
        pressMask = pressed.(forcePlates{idx});
        fpPosTable = cop.(forcePlates{idx})(pressMask, :);
        fpPos=fpPosTable{:,2:end};
        leftFootPos = trc.Left(pressMask, :);
        rightFootPos = trc.Right(pressMask, :);
        leftFootDist = sqrt(sum((fpPos - leftFootPos).^2, 2));
        rightFootDist = sqrt(sum((fpPos - rightFootPos).^2, 2));
        leftAmount = mean(leftFootDist < rightFootDist);
        if isnan(leftAmount)
            % leave as default value
            warning('Force plate %s may not be used.', forcePlates{idx});
        end
        if leftAmount > 0.5
            sides(idx) = 'l';
        end
        if leftAmount > 1/3 && leftAmount < 2/3
            warning('There may be two different feet on force plate %s.', forcePlates{idx});
        end
        % you could also get a more user friendly output by having
        % something like:
        % output.(forcePlates{i}) = sides(i);
        % but the way it is now is good for putting into OpenSim
    end
end
