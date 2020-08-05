function [jointAngleTable,errorTable,motOutputFile] = IK(processedTrcFileName, IKTemplateFile, motOutputFile)
% Osim.IK computes the Inverse Kinematics from a marker file given by
% trcFilename and an IKTemplateFile (in xml format). The results from
% OpenSim are written to motOutputFile, if it is provided. If it is it not
% provided, the output will be written to a random temporary file. If there
% is no time range provided in the xml, it will be set to the length of the
% entire trial by default. Otherwise, it will be left untouched. 
% 
% Files should be OpenSim compatible (i.e. you should be able to run
% OpenSim using the same files used here).
% 
% [jointAngleTable, errorTable, motOutputFile] = Osim.IK(TRCdata, IKTemplateFile, optionalMotOutputFile);
% [jointAngleTable, errorTable, motOutputFile] = Osim.IK(TRCdata, IKTemplateFile);
% 
% 
% Returns:
% jointAngleTable - A table containing joint angles over time. 
% errorTable - The marker error from IK calculations for every marker at
% every frame, stored in a table.
% motOutputFile - The path and file name to the generated MOT file. This
% will be the same as the input motOutputFile if it was provided.
% 
% See also: Osim.editSetupXML, Osim.ID

    
    import org.opensim.modeling.*
    narginchk(2,3);
    
    
    %% Create Inverse Kinematics Setup File
    ikSetupData=xmlread(IKTemplateFile);
    
    processedTrc = Osim.interpret(processedTrcFileName, 'TRC', 'file');
    trcTable = Osim.interpret(processedTrcFileName, 'TRC', 'table');
    timeString = validateTimeRange(IKTemplateFile, trcTable);
    replaceElementValue(ikSetupData, 'time_range', timeString);
    
    %Modify marker_file entries
    replaceElementValue(ikSetupData, 'marker_file', processedTrc);

    %Modify output_motion_file entries
    if ~exist('motOutputFile', 'var')
        motOutputFile = [tempname() '.mot'];
    else
        motOutputFile=GetFullPath(motOutputFile);
    end
    replaceElementValue(ikSetupData, 'output_motion_file', motOutputFile);
    
    % Ensure that marker locations are outputted
    replaceElementValue(ikSetupData, 'report_marker_locations', 'true');
    
    % create a unique results directory so that simultaneous instances of
    % OpenSim do not attempt to overwrite files
    resultsDir = [tempname() filesep];
    replaceElementValue(ikSetupData, 'results_directory', resultsDir);
    
    % model_file holds a path to the .osim model to use for calculating
    % joint angles, which might be an absolute or a relative path. If it
    % is a relative path, it must be changed to an absolute path so that
    % the filled setup xml that is stored in temporary data can access the
    % model. We assume that the model is a relative path with respect to
    % the ikTemplateFile location.
    IKTemplateFilePath=GetFullPath(IKTemplateFile);
    IKTemplateFileRoot=fileparts(IKTemplateFilePath);
   
    
    ikSetupData=relative2abspath(ikSetupData,'model_file',IKTemplateFileRoot);
    
    % Create a temporary file to write the ik setup to
    ikSetupFile = [tempname() '.xml'];
    
    fprintf('Writing inverse kinematics setup file to: %s\n',ikSetupFile);
    xmlwrite(ikSetupFile,ikSetupData);
   
    %% Run Inverse Kinematics in OpenSim
    ikTool = InverseKinematicsTool(ikSetupFile);
    ikTool.run();
    fprintf('Writing inverse kinematics output file to: %s\n',motOutputFile);
    if nargout > 1
        markerResultFile = matchfiles(fullfile(resultsDir, '*locations.sto'));
        %calculateMarkerErrors is defined at the bottom
        stoTable=Osim.readSTO(markerResultFile{1});
        stoTable.Properties.VariableNames(2:end) = cellfun(@(x) {x([1:end-2, end])} , stoTable.Properties.VariableNames(2:end));
        stoTable{:, 2:end} = stoTable{:, 2:end} * 1000; % convert m to mm
        errorTable = Osim.calculateMarkerErrors(trcTable,stoTable);
    end
    jointAngleTable = Osim.readMOT(motOutputFile);    
end
