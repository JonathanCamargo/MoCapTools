function out=getSegmentMarkers(vskFile)
% Get marker structure from vsk model file
% returns a structure with all the  
% out=Vicon.getSegmentMarkers(vskFile)

modelFile=vskFile;


doc=xmlread(modelFile);

markers = doc.getElementsByTagName('TargetLocalPointToWorldPoint');

markerParents=cell(markers.getLength,1);
markerNames=cell(markers.getLength,1);
for i=0:markers.getLength-1
    marker=markers.item(i);
    markerName=marker.getAttribute('MARKER');
    % Warning replace . to _ to make it consistent with matlab field
    % indexing.
    markerName=strrep(char(markerName),'.','_');
    markerNames{i+1}=markerName;
    markerParent=char(marker.getAttribute('SEGMENT'));
    markerParent=strrep(markerParent,'/','');
    markerParent=strrep(markerParent,'.','');
    markerParent = strrep(markerParent, ' ', '');
    markerParents{i+1}=markerParent;
end

unique_segments=unique(markerParents);
for i=1:length(unique_segments)
    idx=strcmp(markerParents,unique_segments(i));
    markers=(markerNames(idx))';
    out.(unique_segments{i})=markers;    
end

names = fieldnames(out);
for i = 1:length(names)
    for j = 1:length(out.(names{i}))
        out.(out.(names{i}){j}) = names{i};
    end
end

%{
%% Get the markers from the vsk file
parameters=doc.getElementsByTagName('Parameter');
for i=0:parameters.getLength-1
    marker=parameters.item(i);
    markerName=marker.getAttribute('NAME');
    markerName=strrep(char(markerName),'.','_');
end
%}