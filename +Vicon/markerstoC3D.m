function c3dFileOut = markerstoC3D(markerStruct, c3dFileOrig, c3dFileOut)
% c3dFileOut = markerstoC3D(markerStruct, c3dFileOrig, c3dFileOut)
% Writes a structure of marker data, such as one taken from
% Vicon.ExtractMarkers, and writes it to a new C3D file, using an old C3D
% file as a reference for any required metadata. c3dFileOrig will not be
% modified, and a new C3D file will be written to c3dFileOut, if it is
% provided. 

    if ~exist('c3dFileOut', 'var')
        c3dFileOut = [tempname() '.c3d'];
    end
    if ~exist('c3dFileOrig', 'var')
        error('You must provide the original C3D file that the marker data was taken from.');
    end
    if ~exist(c3dFileOrig, 'file')
        error('Original C3D file not found.');
    end
    trcTable = Osim.markers2table(markerStruct);
    Vicon.TRCtoC3D(trcTable, c3dFileOrig, c3dFileOut);
end
