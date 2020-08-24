function [newMarkerData,newUnlabeledMarkers]=UnlabelIntervals(markerData,intervals)
  % Unlabel markers from a markerset preserving data unlabeled data as new
  % unlabeled markers. Use a structure intervals to define sections of data to be unlabeled.
  % [markerData,newUnlabeledMarkers]=unlabelIntervals(markerData,intervals)
  
    markerData = Osim.interpret(markerData, 'TRC', 'struct');
    allMarkerNames=fieldnames(markerData);
    newUnlabeledMarkers=struct();
    orig=struct();       
    a=struct2cell(intervals);    
    intervalNames=fieldnames(intervals);    
    intervalNames=intervalNames(cellfun(@(x)~isempty(x),a));
    if isempty(intervalNames)
        newMarkerData=markerData;
        return;
    end
    for i=1:numel(intervalNames)
        intervalName=intervalNames{i};
        justOneMarker=Topics.select(markerData,intervalName);
        if isempty(intervals.(intervalName))
            continue;
        end
        segments=Topics.segment(justOneMarker,intervals.(intervalName),intervalName);
        a=[segments{:}]; 
        aa=vertcat(a.(intervalName)); 
        [~,idx]=unique(aa.Header);
        orig.(intervalName)=aa(idx,:);
    end
    cleaned=Topics.transform(@(x)(x*nan),orig,intervalNames);    
    removedSections=struct2cell(orig);
    newNames=compose('C_%d',numel(allMarkerNames)+(1:numel(removedSections)));
    newUnlabeledMarkers=cell2struct(removedSections,newNames);
    nantable=markerData.(allMarkerNames{1}); nantable{:,2:end}=nan;
    initializeTable_fun=@(x)(nantable);
    initializedUnlabeledMarkers=Topics.processTopics(initializeTable_fun,newUnlabeledMarkers,newNames);
    newUnlabeledMarkers=Topics.merge(initializedUnlabeledMarkers,newUnlabeledMarkers);
    % Combine unlabeled and markerData with cleaned labeled markers
    newMarkerData=Topics.merge(markerData,cleaned);        
    % Check and clean newUnlabeledMarkers from all empty data
    a=Topics.processTopics(@(x)(all(isnan(x{:,2:end}),'all')),newUnlabeledMarkers,newNames);
    topicsToRemove=newNames((struct2array(a)==1));
    newUnlabeledMarkers=Topics.remove(newUnlabeledMarkers,topicsToRemove);        
end