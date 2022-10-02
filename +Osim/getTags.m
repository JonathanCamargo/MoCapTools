function h = getTags(xml)
% For an xml file, return all of the tag names in a cell array for viewing,
% so that some can be selected and passed into Osim.editSetupXML()
% 
% Usage: Osim.getTags(xmlFile);
% Example: Osim.getTags('./myXmlFile.xml');
% 
% 
% See also: Osim.editSetupXML

    obj = xmlread(xml);
    h = unique(childHeaders(obj));
end

function h = childHeaders(node)
    len = node.getLength();
    h = [];
    for idx = 0:len-1
        childNode = node.item(idx);
        newName = childNode.getNodeName.toCharArray()';
        if startsWith(newName, '#')
            continue;
        end
        childH = childHeaders(childNode);
        h = [h; {newName}; childH];
    end
end
