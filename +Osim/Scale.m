function Scale(processedStaticTRCFilename,scaleTemplateFile,outputOsimFile)
% OpenSimScale generates the scaled model outputOsimFile by using a markers
% file staticTrcFileName and a scaleTemplateFile (in xml format)
%
% Scale(processedStaticTRCFilename,scaleTemplateFile,outputOsimFile)
% Returns:
% None. This function creates a .osim file given by outputOsimFile
%
%
% Opensim scripts use tempfolder for intermediate steps, for those files
% we need to reference original files as absolute paths.

    narginchk(3,3);
    
    import org.opensim.modeling.*

    processedStaticTRC = Osim.interpret(processedStaticTRCFilename, 'TRC', 'file');
    trcTable = Osim.interpret(processedStaticTRCFilename, 'TRC', 'table');
    timeString = validateTimeRange(scaleTemplateFile, trcTable);
    
    %We start with a given scale templatefile we edit the template file to use a specific trc file
    % with static data and run the opensim scaling to produce a modified osim model.
    %Create a temporal file for the scale setup configuration using specific trc file. 
    scaleSetupFile=[tempname() '.xml'];   	
        
    %Since OpenSim API does not allow for saving intermediate xml files
    %I am using xmlread from matlab to edit xml and save them. The
    %alternative is using opensim to load the scale.xml as a scaletool object
    % and edit that programaticaly and then run the scale tool. I want to
    % do xml instead since it is easier to test with the opensim gui than 
    % doing everything from matlab code.
    doc=xmlread(scaleTemplateFile);
    
    replaceElementValue(doc, 'time_range', timeString);
    
    if doc.getElementsByTagName('ScaleTool').getLength() == 0
        error('This is not an OpenSim scale XML.');
    end
    
    %Reference files as absolute path
    scaleTemplateFilePath=GetFullPath(scaleTemplateFile);
    scaleTemplateFileRoot=fileparts(scaleTemplateFilePath);
    
    doc=updatePathReference(doc,{'model_file','marker_set_file'},scaleTemplateFileRoot);

    %Modify marker_file entries
    [~, filename] = fileparts(processedStaticTRC);
    replaceElementValue(doc, 'marker_file', [filename '.trc']);
    
    % Create a path for the output to be written to. The output will be
    % copied from this path to the path that the user has inputted. 
    tempOutputModel = [tempname() '.osim'];
    [~, filename] = fileparts(tempOutputModel);
    replaceElementValue(doc, 'output_model_file', [filename '.osim']);
    
    % set the name of the model to be the same as the filename 
    elem = doc.getElementsByTagName('ScaleTool').item(0);
    [~, name, ~] = fileparts(outputOsimFile);
    elem.setAttribute('name', name);
    
    % only update the time range if there is not already one present
    curTimeRange = str2num(doc.getElementsByTagName('time_range').item(0).getTextContent().toCharArray()');
    if isempty(curTimeRange)
        %Modify time_range entries
        replaceElementValue(doc, 'time_range', timeString);
    end
        
    fprintf('Writing scale setup file to: %s\n',scaleSetupFile);
    xmlwrite(scaleSetupFile,doc);
    
    scaleTool = ScaleTool(scaleSetupFile);
    try
        scaleTool.run();
    catch e
        if isequal(e.identifier, 'MATLAB:invalidConversion') && ...
            isequal(e.message, 'Conversion to double from org.opensim.modeling.ScaleTool is not possible.') && ...
            isequal(e.stack(1).file, which('run'))
            % scale using scale.exe in C:/OpenSim*/bin 
            system(sprintf('scale -S "%s"', scaleSetupFile));
        else
            rethrow(e);
        end
    end
    copyfile(tempOutputModel, outputOsimFile);
end
