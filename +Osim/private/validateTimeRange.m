function timeString = validateTimeRange(setupXML, dataTable)
% Look at the xml file for a time range. If there is one, then check if it
% is valid, then return the same value. If there is not one, determine what
% it should be, then return it. 

    curTimeRange = str2num(Osim.readTagFromXML(setupXML, 'time_range'));
    if isempty(curTimeRange) % if there is no time range set, set a default one
        startTime=dataTable.Header(1);
        endTime=dataTable.Header(end);
    else % otherwise, make sure that the selected time range is valid 
        startTime = curTimeRange(1);
        endTime = curTimeRange(2);
        dataTable = Topics.cut(dataTable, startTime, endTime);
    end
    noDataFrames = all(isnan(dataTable{:, 2:end}), 2);
    if any(noDataFrames)
        error('The input file has regions with no data, which will cause OpenSim to crash. Modify the time range manually or update the input data file.');
    end
    timeString=sprintf('%f %f',startTime,endTime);
end
