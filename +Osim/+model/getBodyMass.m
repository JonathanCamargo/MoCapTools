function [bodynames, massvalues] = getBodyMass(xmlFile)
% [bodynames, massvalues] = editBodyMass(xmlFile)
% Read the bodies and masses from an opensim model

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
    massvalues=nan(elems.getLength,1);
    for i=0:elems.getLength-1
        b=elems.item(i);
        bodynames{i+1}=b.getAttribute('name').toCharArray';        
        massobj=b.getElementsByTagName('mass').item(0);
        massstr=massobj.getTextContent().toCharArray';
        massvalues(i+1)=str2double(massstr);
    end
    
end
