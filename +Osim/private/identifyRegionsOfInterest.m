function locations = identifyRegionsOfInterest(FPFile)
% Identify the segments of a trial in which we care about the error, using
% force plate data.  This occurs between the foot down of the first force
% plate and the foot up of the last force plate, but not between the foot
% up of the last force plate and the foot down of the first force plate of
% the next trial run.  This is identified using rising and falling edges.

    fpTable = FP2table(FPFile); % Create a table from the FP2table function.
        
    % Process the table to isolate the y directional data of the force
    % plates and change the frame rate to match TRC
    goodCols = [true, contains(fpTable.Properties.VariableNames(2:end), '_vy')];
    fpTable = fpTable(1:5:end, goodCols); % remove unwanted columns and update frame rate to match trc
    
    % initialize locations
    locations = false(1, height(fpTable));
    
    % if the trial is neither a ramp nor stair trial, then all of it is
    % relevant 
    if ~contains(lower(FPFile), 'ramp') && ~contains(lower(FPFile), 'stair')
        locations = ~locations;
        return;
    end

    
    edge1 = fpTable.Amp1_vy > 5; % Isolate the area of the table data for 
                                 % both force plates where the edge is 
                                 % greater than 5.
    edge5 = fpTable.Amp5_vy > 5;
    
    % Using a convolution function, identify the areas of rising and
    % falling edges.  The rising edge is represented by a 1, and the
    % falling edge represented by -1.
    edgesOf1 = conv(edge1, [1 -1]);
    edgesOf5 = conv(edge5, [1 -1]);

    % Using a cell array, store rising and falling edges for each
    % of the separate force plates.
    intervals = {};
    rising1 = find(edgesOf1 == 1);
    falling1 = find(edgesOf1 == -1);
    rising5 = find(edgesOf5 == 1);
    falling5 = find(edgesOf5 == -1);
    
    % For each pair of rising and falling force plate data, there can be
    % identified an up and down ramp motion.  The area between the first
    % rising edge of the first force plate and the falling edge of the last
    % force plate represents the uphill walking, whereas the area between
    % the first rising edge of the last force plate and the last falling 
    % edge of the first force plate represent the downhill walking.
    for i = 1:2:length(rising1)
        intervals = [intervals; {[rising5(i), falling1(i)]}; {[rising1(i + 1), falling5(i + 1)]}];
    end
    
    % Create a vector of values that are a range of numbers, one apart,
    % that represent the indices between the ranges of incorrect values.
    validLocs = cellfun(@(x) x(1):x(end), intervals, 'UniformOutput', false);
    validLocs = [validLocs{:}];
    
    % Set the areas between the intervals to false.
    locations(validLocs) = true;
end
