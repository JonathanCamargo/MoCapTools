function trcTable = readTRC(file)
% Takes a TRC file and removes the subject ID from the marker names if
% present, replaces any gaps with NaN, and exports the new data to a table.
% Usage: TRCTABLE = readTRC(FILE), where:
% FILE is the name of the .trc file to be processed, including a relative
% or absolute path (ex. '..\Data\stair\VIC\Stair_1_R_01.trc').
% TRC_TABLE is a table containing all the data stored in the original TRC
% file. 
    
    narginchk(1, 1);
    assert(ischar(file) && endsWith(lower(file), '.trc'), 'This is not a TRC file (*.trc).');
    % Import data from file
    fh = fopen(file);
    fgetl(fh);
    fgetl(fh);
    fgetl(fh);
    l = fgetl(fh);
    fclose(fh);
    markers = strsplit(l, '\t');
    data = dlmread(file, '\t', 5, 0);
    
    % get the subject ID
    % this will return some garbage if there is no subject id, but it won't
    % mess up the file
    subjectID = strtok(markers{3}, ':'); 
    % remove the subject ID
    % if there was no subject ID to start with, strrep will not find any
    % matches for [subjectID ':'] and won't replace anything
    markers = strrep(markers, [subjectID ':'], '');
    labels = markers(3:end-1);
    labels = labels(:);
    out = array2table(data(:,2:end));
    
    colNames = compose('%s_%c', string(labels), 'xyz')';
    
    varNames = [{'Header'}, colNames(:)'];
    
    out.Properties.VariableNames = varNames;
    
	trcTable=out;
end
