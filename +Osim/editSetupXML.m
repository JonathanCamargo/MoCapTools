function outputFile = editSetupXML(xmlFile, varargin)
% Edit the text in an XML file by tag name. Can be used to change certain
% parameters of OpenSim setup XML files before running scaling, IK, or ID.
% 
% outputFile = editSetupXML(xmlFile, varargin)
% 
% xmlFile is the path and filename of the XML to be edited. 
% outputFile is a path to the new file created. 
% 
% Description of optional inputs: 
% FilePath: the path and filename that the edited XML should be written
% to. If this input is not provided, the file will be written to a random
% location in the temporary directory. 
% <tag_name>: the value that the given tag name should be replaced with, as
% either a character vector, or a cell array of character vectors if there
% are multiple elements with the same tag name. This input can be repeated
% several times for each tag name to be replaced. 
% 
% Example: 
% 
% outputFile = Osim.editSetupXML('oldFile.xml', 'FilePath', 'newFile.xml', 'model_name', 'newOsimFile.osim', 'accuracy', '1e-6');
% outputFile = Osim.editSetupXML('oldFile.xml', 'time_range', '0 3.15', 'model_name', 'newOsimFile.osim');
%

    narginchk(1, inf);
    p = inputParser;
    p.addRequired('xmlFile', @ischar);
    p.addParameter('FilePath', [tempname() '.xml'], @ischar);
    p.KeepUnmatched = true;
    p.parse(xmlFile, varargin{:});
    inputs = p.Unmatched;
    outputFile = p.Results.FilePath;
    
    xmlObj = xmlread(xmlFile);
    tagNames = fieldnames(inputs);
    for idx = 1:length(tagNames)
        tagName = tagNames{idx};
        value = inputs.(tagName);
        replaceElementValue(xmlObj, tagName, value);
    end
    if ~contains(tagNames, 'model_file')
        xmlObj=relative2abspath(xmlObj,'model_file',fileparts(GetFullPath(xmlFile)));
    end
    xmlwrite(outputFile, xmlObj);
end
