function [bodynames, comvalues] = getMassCenter(xmlFile)
% [bodynames, massvalues] = getMassCenter(xmlFile)
% Read the masses from an opensim model and the mass center relative to the
% local segment coordinates.

    narginchk(1, inf);
    p = inputParser;
    p.addRequired('xmlFile', @ischar);
    %p.addParameter('FilePath', [tempname() '.xml'], @ischar);
    p.KeepUnmatched = true;
    p.parse(xmlFile);        
    
    xmlObject = xmlread(xmlFile);
    elems = xmlObject.getElementsByTagName('Body');
    if elems.getLength == 0
        warning('Tag name "%s" not found.', 'Body');
    end
    
    bodynames=cell(elems.getLength,1);
    comvalues=cell(elems.getLength,1);
    for i=0:elems.getLength-1
        b=elems.item(i);
        bodynames{i+1}=b.getAttribute('name').toCharArray';        
        massobj=b.getElementsByTagName('mass_center').item(0);
        massstr=massobj.getTextContent().toCharArray';
        comvalues{i+1}=cellfun(@str2double,split(massstr))';
    end
    
end
