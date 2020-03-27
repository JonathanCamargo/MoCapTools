function trcFile = markers2TRC(markerStruct, varargin)
% Takes in a struct of marker data, such as one outputted by
% Vicon.ExtractMarkers, and writes it to a TRC file that can be used in
% OpenSim. 
% 
% trcFile = markers2TRC(markerStruct, varargin)
% 
% Description of optional inputs: 
% 
% FilePath: the file that the trc table should be written to. If this input
% is not provided, the data will be written to a random location in the
% temporary directory. 
% FilterFreq: The cutoff frequency that the data should be filtered at
% using a 4th order zero lag Butterworth filter. If FilterFreq is not
% provided, the data will be filtered at 6 Hz by default. If the data
% should not be filtered, FilterFreq should be set to a negative value. 

    assert(isstruct(markerStruct), 'Input must be a struct.');
    
    markerTable = Osim.markers2table(markerStruct);

    trcFile = Osim.writeTRC(markerTable, varargin{:});
end
