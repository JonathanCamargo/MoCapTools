function out = readMOT(motFile)
% Parses MOT file, which may be either force plate data or inverse
% kinematics data, and outputs a table containing the same information. 
% 
% motTable = readMOT(motFile)

    assert(ischar(motFile) && endsWith(lower(motFile), '.mot'), 'This is not a MOT file (*.mot).');
    
    data = importdata(motFile);
    if iscell(data)
        data = importdata(motFile, ' ');
    end
    out = array2table(data.data);
    
    if isfield(data, 'colheaders')
        headers = data.colheaders;
    else
        headers = split(data.textdata{end, :});
    end
    headers(cellfun('isempty', headers)) = [];
    headers = strrep(headers, '/', '_');
    headers = strrep(headers, '.', '_');
    headers = strrep(headers, '\', '_');
    headers = genvarname(headers);
    
    headers{1}='Header';
    out.Properties.VariableNames = headers;
end
