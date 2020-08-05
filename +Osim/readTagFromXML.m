function value = readTagFromXML(xml, tag)
    xmlDoc = xmlread(xml);
    value = char(xmlDoc.getElementsByTagName(tag).item(0).getTextContent());
end
