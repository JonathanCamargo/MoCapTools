function xmlObject=relative2abspath(xmlObject, elementNames,root)
    %Edit the content in every tag in elementNames to transform from relative to
    %absolute path.
    %e.g relative2abspath(doc,{'marker_file','model_file'},'.')
    % This will go through the doc xml and change content of marker_file
    % and model_file to make them absolute path. Since root is '.' it will
    % consider relativeness with respect to pwd.
    
    if ischar(elementNames)
        elementNames={elementNames};
    end
    root=GetFullPath(root);
    for element_idx=1:numel(elementNames)
        elems = xmlObject.getElementsByTagName(elementNames{element_idx});
        for i = 0:elems.getLength-1
            item = elems.item(i);
            % get the path in the tag element
            pathValue = char(item.getTextContent);
            % if the path is already absolute, do nothing
            if ~java.io.File(pathValue).isAbsolute()
                pathValue = fullfile(root,pathValue);
            end
            % Check if file exists
            if ~exist(pathValue,'file')
                error('File not found: %s',pathValue);
            end
            %Change the value in the tag to the absolute path
            item.setTextContent(pathValue);
        end
    end
end
