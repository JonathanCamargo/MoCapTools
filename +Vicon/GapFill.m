function markerData = GapFill(markerData, modelFile, varargin)
% GapFill  Gap-fills marker data using modelFile to determine segments
% markerData = GapFill(markerData, modelFile, varargin)
%   In:
%       markerData - marker data as either a struct, table, or file
%       modelFile - a scaled .osim model or a .vsk file of the subject used
%                   to determine segments
%                   
%   Optional Inputs:
%       VerboseLevel - 0 (minimal, default), 1 (normal), 2 (debug mode)
%       
%   Out:
%       markerData - struct of filled marker data
%
%   See also: Vicon.GapMake, Vicon.IterativeGapFilling.

%% User starts with:

p = inputParser;
p.addParameter('VerboseLevel',0);

p.parse(varargin{:});

verboseLevel = p.Results.VerboseLevel;
markerData = Osim.interpret(markerData, 'TRC', 'struct');
markers = fieldnames(markerData);
if endsWith(modelFile, '.osim')
    segments = Osim.model.getSegmentMarkers(modelFile);
elseif endsWith(modelFile, '.vsk')
    segments = Vicon.getSegmentMarkers(modelFile);
else
    error('Could not identify segment information from osim model.');
end
[~, valid_marker, ~] = intersect(fieldnames(markerData),fieldnames(segments));

% remove markers in markerData which are not attached to a segment
markerData = rmfield(markerData, setdiff(markers, markers(valid_marker)));

% remove references to markers with no data (medials) from segments struct
markersWithNoData = setdiff(fieldnames(segments), fieldnames(markerData));
for idx = 1:length(markersWithNoData)
    marker = markersWithNoData{idx};
    seg = segments.(marker);
    if ischar(seg)
        segments.(seg) = setdiff(segments.(seg), marker);
    end
end

%%
gapTable = genGapTable(markerData);

if height(gapTable) == 0
    warning('There are no gaps in this file. Are you sure?')
else
    
    change = true;
    if height(gapTable) == 0
        change = false;
    end
    
    rbFills = 0;
    ptFills = 0;
    shortSpFills = 0;
    spFills = 0;
    %h = progress(0);
    idx = 1;

    % spline fill really short gaps
    while (idx<=height(gapTable) && gapTable.Length(idx) == 1 )
        markerData = Vicon.SplineFill(markerData, gapTable.Markers{idx}, gapTable.Start(idx), gapTable.End(idx));
        shortSpFills = shortSpFills + 1;
        idx = idx + 1;
        %progress(idx/sum(gapTable.Length == 1), h);
    end
    
    gapTable = genGapTable(markerData);
    
    while change
        while change
            change = false;
            %h = progress(0);
            for i = 1:height(gapTable)
                gap = [gapTable.Start(i) gapTable.End(i)];
                markerName = gapTable.Markers{i};
                donors = segments.(segments.(markerName));
                donors = setdiff(donors, markerName); % remove the marker from the donor list
                try
                    markerData = Vicon.RigidBodyFill(markerData, markerName, donors, gap(1), gap(2));
                    rbFills = rbFills + 1;
                    change = true;
                catch E
                    if ~startsWith(E.identifier, 'GapFill:')
                        rethrow(E);
                    end
                    try
                        markerData = Vicon.PatternFill(markerData, markerName, donors, gap(1), gap(2));
                        ptFills = ptFills + 1;
                        change = true;
                    catch E
                        if ~startsWith(E.identifier, 'GapFill:')
                            rethrow(E);
                        end
                    end
                end
                %progress(i/height(gapTable), h);
            end
            gapTable = genGapTable(markerData);
        end
        
        if height(gapTable) == 0
            change = false;
        else
            gapTableSize = height(gapTable);
            if verboseLevel > 0
                if gapTable.Length(1) > 10
                    warning('Spline-filling Large gap');
                end
            end
            [markerData,err] = Vicon.SplineFill(markerData, gapTable.Markers{1}, gapTable.Start(1), gapTable.End(1));
            if ~err
                spFills = spFills + 1;
                gapTable = genGapTable(markerData);                
                change = true;
            else
                change=false;
                unFilledGaps=height(gapTable);
            end            
        end
    end
    %delete(h);
    unFilledGaps=height(gapTable);
    if verboseLevel > 0
        fprintf(['   %d gaps filled with rigid body fill.\n' ...
            '   %d gaps filled with pattern fill.\n' ...
            '   %d gaps filled with spline fill.\n' ...
            '   %d one-frame gaps filled with spline fill.\n'], rbFills, ptFills, spFills, shortSpFills);
        if unFilledGaps>0
            fprintf(' %d gaps could not be filled\n',unFilledGaps);
        end
    else
        fprintf('   %d gaps filled\n', rbFills + ptFills + spFills + shortSpFills);
        if unFilledGaps>0
            warning(' %d gaps could not be filled\n',unFilledGaps);
        end
    end
end
end

function gapTable = genGapTable(markerData)
gaps = Vicon.findGaps(markerData);
markers = fieldnames(markerData);

gapIndices = cell2mat(struct2cell(gaps));
gapMarker = cell(size(gapIndices, 1), 1);
gapsCounted = 0;
for i = 1:length(markers)
    numberOfGaps = size(gaps.(markers{i}),1);
    gapMarker((1:numberOfGaps) + gapsCounted) = markers(i);
    gapsCounted = gapsCounted + numberOfGaps;
end


if gapsCounted==0
    gapTable=table();
    return;
end

gapTable = array2table(gapIndices,'VariableNames',{'Start','End'});
markerTable = cell2table(gapMarker,'VariableNames',{'Markers'});
gapTable = [gapTable markerTable];
gapTable.Length = gapTable.End - gapTable.Start - 1;
gapTable = sortrows(gapTable,'Length');
end
