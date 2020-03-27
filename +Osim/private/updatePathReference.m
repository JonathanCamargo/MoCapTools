% this function takes an xml object outputted by xmlread and copies the
% path referenced in elementName to a temporary file, and redirects
% elementName to point to the new temporary file
function xmlObject=updatePathReference(xmlObject, elementNames, root)
    % eg. updatePathReference(doc,{'marker_file','model_file'},'.')
    % This will go through the doc xml and change content of marker_file
    % and model_file to make them absolute path. Since root is '.' it will
    % consider relativeness with respect to pwd.
    
    if ischar(elementNames)
        elementNames={elementNames};
    end
    
    for element_idx=1:numel(elementNames)
        elems = xmlObject.getElementsByTagName(elementNames{element_idx});
        for i = 0:elems.getLength-1
            item = elems.item(i);
            % get the path in the tag element
            curPath = char(item.getTextContent);
            fileObj = java.io.File(curPath);
            if fileObj.isAbsolute()
                pathValue = curPath;
            else
                pathValue = fullfile(root,curPath);
            end
            % Check if file exists
            if ~exist(pathValue,'file')
                error('File not found: %s',pathValue);
            end
            % create a filename for the copied file and create it
            [~,~,ext] = fileparts(pathValue);
            copy = [tempname() ext];
            copyfile(pathValue, copy);
            [~, copyname,ext] = fileparts(copy);
            copyname = [copyname ext];
            % update the reference
            item.setTextContent(copyname);
        end
    end
end
