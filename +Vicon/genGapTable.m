function gapTable = genGapTable(markerData)
% gapTable = genGapTable(markerData)
% Generate a table with the gaps from a marker dataset

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