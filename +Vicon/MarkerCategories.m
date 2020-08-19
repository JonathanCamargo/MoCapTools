function [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames,labeledMarkers,labeledMarkerNames] = MarkerCategories(allMarkers)
% For a set of markerdata split the markers in labeled/unlabeled categories
% [allMarkerNames,unlabeledMarkers,unlabeledMarkerNames,labeledMarkers,labeledMarkerNames] = MarkerCategories(allMarkers)

    allMarkers=Osim.interpret(allMarkers,'TRC','struct');
    allMarkerNames=fieldnames(allMarkers);
    unlabeledMarkerNames=allMarkerNames(contains(allMarkerNames,'C_'));
    labeledMarkerNames=allMarkerNames(~contains(allMarkerNames,'C_'));

    labeledMarkers=Topics.select(allMarkers,labeledMarkerNames);
    unlabeledMarkers=Topics.select(allMarkers,unlabeledMarkerNames);
    

end