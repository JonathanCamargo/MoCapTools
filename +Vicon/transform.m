function arraydata = transform(arraydata,format)
% Transform an array to Vicon or Osim coordinate frames
% This assumes that the array has only 3*n columns for (x, y, z) coordinate
% data, and has no initial columns for time, etc. 
%
% tabledata = Vicon.transform(coordinateArray,format)
%
% tabledata is the data to be transformed
% format can be 'OsimXYZ' to transform from Vicon to Osim
%               'ViconXYZ' to transform from Osim to Vicon
%               R (matrix)    an arbirary 3x3 rotation matrix
% To transform table data that has a column for time: 
% tabledata{:, 2:end} = Vicon.transform(tabledata{:, 2:end}, format);
% 


   % do a coordinate transformation for every marker, then write the
    % output
    rot_VICtoOSIM = [1, 0, 0; % rotation matrix for a single marker
            0, 0, -1;
            0, 1,0];
    
    if ~isnumeric(format)
        if strcmpi(format,'OsimXYZ')
            rot3=rot_VICtoOSIM;
        elseif  strcmpi(format,'ViconXYZ')
            rot3=rot_VICtoOSIM';
        else
            error('Reference system format not supported');
        end
    else
        rot3=format;
    end
    % construct a block diagonal matrix that has rot3 on the main diagonal,
    % with nPoints many copies so that we can transform all points at once
    nPoints = size(arraydata, 2)/3;
    if floor(nPoints) ~= nPoints
        error('This array has extra columns.')
    end
    rotMatrix = repmat({rot3}, 1, nPoints);
    rotMatrix = blkdiag(rotMatrix{:});    
    nanIdx=isnan(arraydata);
    arraydata(nanIdx)=0;
    arraydata = arraydata * rotMatrix; 
    arraydata(nanIdx)= NaN;
end
