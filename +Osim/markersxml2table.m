function tbl=markersxmlToTable(markersxmlfile,fk_h)
% Convert markers from opensim format to TRC to visualize standard model
% and markers in blender

xmlObj = xmlread(markersxmlfile);
m=getElementsByTagName(xmlObj,'Marker');

markerstruct=struct();
for i=1:m.getLength
    marker=m.item(i-1);
    name=marker.getAttribute('name').toCharArray';
    
    l=marker.getElementsByTagName('location');
    l=l.item(0).item(0).getTextContent;
    loc=str2num(l);
    
    p=marker.getElementsByTagName('socket_parent_frame');
    p=p.item(0).item(0).getTextContent.toCharArray';
    parent=strrep(p,'/bodyset/','');
    
    H=fk_h.(parent);
    
    tbl=table();
    tbl.Header=fk_h.Header;
    tbl.x=zeros(size(fk_h,1),1);
    tbl.y=zeros(size(fk_h,1),1);
    tbl.z=zeros(size(fk_h,1),1);
    
    
    for j=1:size(fk_h,1)
        x=H{j}*[loc';1];
        tbl{j,2:end}=x(1:3)';        
    end
    markerstruct.(name)=tbl;            
    
end

tbl=Osim.markers2table(markerstruct);


end