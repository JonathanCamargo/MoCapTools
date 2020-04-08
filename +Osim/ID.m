function [JointTorquesTable, stoOutputFile]=ID(GRFMotFile,IDTemplateFile,IKMotFile,stoOutputFile)
% Osim.ID computes the inverse Dynamics from forceplate data given by
% GRFdata, an IDTemplateFile (in xml format), and IKdata which is a
% Joint Kinematics file obtained from Osim.IK. The output will be written
% to stoOutputFile if it is provided. If there is no time range provided in
% the xml, it will be set to the length of the entire trial by default.
% Otherwise, it will be left untouched. 
% 
% [JointTorquesTable, stoOutputFile]=Osim.ID(GRFdata,IDTemplateFile,IKdata,stoOutputFile)
% [JointTorquesTable, stoOutputFile]=Osim.ID(GRFdata,IDTemplateFile,IKdata)
% GRFdata can be a path to a .mot file, a path to a .mat file, or a table
% of force plate data. 
% IKdata can be a path to a .mot file, a path to a .mat file, or a table
% of IK data. It does not have to be the same type as GRFdata.
% Returns:
% JointTorquesTable
% stoOutputFile: a path to the file created by OpenSim
% 
% See also: Osim.editSetupXML, Osim.IK

    import org.opensim.modeling.*
    narginchk(3,4);
    
    GRFMotFile = Osim.interpret(GRFMotFile, 'MOT', 'file');
    IKMotFile = Osim.interpret(IKMotFile, 'MOT', 'file');
    IKMotData = Osim.interpret(IKMotFile, 'MOT', 'table');
    timeString = validateTimeRange(IDTemplateFile, IKMotData);
    
    %% Create Inverse Dynamics Setup File
    idSetupData=xmlread(IDTemplateFile);
    replaceElementValue(idSetupData, 'time_range', timeString);
    
    %Make results directory the same directory of the xml
    replaceElementValue(idSetupData, 'results_directory', '.');

    %% Create External Loads File
    %Read the external loads file location from the idSetupData
    pathValue = Osim.readTagFromXML(IDTemplateFile, 'external_loads_file');
    %The path to the extLoads file can be either absolute or relative to
    %the idtemplate xml. Check for both.
    if exist(GetFullPath(pathValue),'file')
        %Absolute path
        externalLoadsTemplatePath=GetFullPath(pathValue);
    else 
        fullIdTemplateFile=GetFullPath(IDTemplateFile);
        [folder,~,~]=fileparts(fullIdTemplateFile);
        externalLoadsTemplatePath=fullfile(folder,pathValue);
        externalLoadsTemplatePath=GetFullPath(externalLoadsTemplatePath);
        if ~exist(externalLoadsTemplatePath,'file')
            error('External loads file not found at %s',externalLoadsTemplatePath);
        end
    end
    % Copy and edit the external loads file to change the mot file it points to.
    externalLoadsDoc=xmlread(externalLoadsTemplatePath);
    fullGRFMotFile=GetFullPath(GRFMotFile);
    if ~exist(fullGRFMotFile,'file')
        error('Force plate mot file not found at %s',fullGRFMotFile);
    end
    replaceElementValue(externalLoadsDoc, 'datafile',fullGRFMotFile);
    % Save the modified external loads xml as a copy
    externalLoadsFile = [tempname() '.xml'];
    xmlwrite(externalLoadsFile,externalLoadsDoc);
    
    %% Modify the ID template with new configurations:
    
    % Point to new external loads file in idSetupData
    replaceElementValue(idSetupData, 'external_loads_file',externalLoadsFile);

    %Modify time_range entries coordinates_file
    IKMotFile=GetFullPath(IKMotFile);
    replaceElementValue(idSetupData, 'coordinates_file', IKMotFile);
    tempStoOutputFile = [tempname() '.sto'];
    %Since the results directory is the temp folder
    
    [~,stoOutputFileName,ext]=fileparts(tempStoOutputFile);
    replaceElementValue(idSetupData, 'output_gen_force_file', [stoOutputFileName ext]);
            
    
    % model_file holds a path to the .osim model to use for calculating
    % joint angles, which might be an absolute or a relative path. If it
    % is a relative path, it must be changed to an absolute path so that
    % the filled setup xml that is stored in temporary data can access the
    % model. We assume that the model is a relative path with respect to
    % the idTemplateFile location.
    IDTemplateFilePath=GetFullPath(IDTemplateFile);
    IDTemplateFileRoot=fileparts(IDTemplateFilePath);  
    idSetupData=relative2abspath(idSetupData,'model_file',IDTemplateFileRoot);
    
    % Create a temporary file to write the ik setup to
    idSetupFile = [tempname() '.xml'];
    
    fprintf('Writing inverse dynamics setup file to: %s\n',idSetupFile);
    xmlwrite(idSetupFile,idSetupData);
   
    %% Run Inverse Dynamics in OpenSim
    idTool = InverseDynamicsTool(idSetupFile);
    idTool.run();
    
    if ~exist('stoOutputFile', 'var')
        stoOutputFile = tempStoOutputFile;
    else
        stoOutputFile = GetFullPath(stoOutputFile);
        copyfile(tempStoOutputFile,stoOutputFile);
    end
    
    fprintf('Writing inverse dynamics output file to: %s\n',stoOutputFile);
    JointTorquesTable = Osim.readSTO(stoOutputFile);
end
