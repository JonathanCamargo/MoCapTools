function replaceElementValue(xmlObject, elementName, newValue)
% Takes the xml object outputted by xmlread and replaces the value of all
% elements matching the name given by elementName to newValue
    assert(ischar(newValue) || iscellstr(newValue), ...
        'Value provided must be a character vector of a cell array of character vectors.');

    elems = xmlObject.getElementsByTagName(elementName);
    if elems.getLength == 0
        warning('Tag name "%s" not found.', elementName);
    end

    for i=0:elems.getLength-1
        if iscell(newValue)
            val = newValue{elemIdx + 1};
        else
            val = newValue;
        end
        curItem=elems.item(i);
        curItem.setTextContent(val);
    end
end
