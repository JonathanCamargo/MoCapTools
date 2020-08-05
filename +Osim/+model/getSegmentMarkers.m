function out=getSegmentMarkers(osimModelFile)
% Get marker structure from model file
% 
% out=getSegmentMarkers(osimModelFile)

modelFile=osimModelFile;


doc=xmlread(modelFile);

osdoc = doc.getElementsByTagName('OpenSimDocument');
osdoc = osdoc.item(0);
docversion = osdoc.getAttribute('Version').toCharArray()';
switch docversion
    case '40000'
        parentTagName = 'socket_parent_frame';
    case '30516'
        parentTagName = 'socket_parent_frame_connectee_name';
    case '30000'
        parentTagName = 'body';
    otherwise
        warning('This .osim file may need to be converted to the newest version.');
end

elems = doc.getElementsByTagName('MarkerSet');
a=elems.item(0);
markers=a.getElementsByTagName('Marker');

markerParents=cell(markers.getLength,1);
markerNames=cell(markers.getLength,1);
for i=0:markers.getLength-1
    marker=markers.item(i);
    markerName=marker.getAttribute('name');
    % Warning replace . to _ to make it consistent with matlab field
    % indexing.
    markerName=strrep((markerName.toCharArray)','.','_');
    markerNames{i+1}=markerName;
    a=marker.getElementsByTagName(parentTagName).item(0);
    markerParent=(a.getTextContent().toCharArray)';
    markerParent=strrep(markerParent,'/','');
    markerParent=strrep(markerParent,'.','');
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
