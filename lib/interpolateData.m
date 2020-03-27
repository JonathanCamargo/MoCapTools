function data = interpolateData(data)
    % fills gaps in data by linearly interpolating columnwise
    for col = 1:size(data, 2)
        startGap = -1;
        endGap = -1;
        inGap = false;
        for row = 1:size(data, 1)
            if ~inGap && isnan(data(row, col))
                if row == 1
                    warning('NaN value found in first row of column %d. Skipping gap...', col);
                end
                startGap = row;
                endGap = -1;
                inGap = true;
            end
            if inGap && ~isnan(data(row, col))
                endGap = row;
                inGap = false;
            end
            if ~inGap && endGap > -1
                if startGap > 1
                    data(startGap:endGap-1, col) = linspace(data(startGap-1, col), data(endGap, col), endGap-startGap);
                end
                endGap = -1;
            end
        end
    end
end