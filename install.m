!synclient HorizEdgeScroll=0 HorizTwoFingerScroll=0
clc; clear; close all;

fprintf('Installing sf_pre...\n');

%% Add the paths as needed
addpath(genpath('extlib'));
addpath(genpath('lib'));
addpath('.');
openSimJustAdded = false;
try 
    org.opensim.modeling.Model;
	fprintf('OpenSim bindings already installed\n');
catch
    try
        fprintf('Adding OpenSim libraries to path\n');
        osimPath=fullfile('C:/Users/', getenv('username'), '/Documents/OpenSim/*/Code/Matlab');
        scripts=matchFiles(osimPath, 'configureOpenSim.m');
        if isempty(scripts)
            fprintf('OpenSim scripts not found in %s\nSearching in %s\n', osimPath, fullfile('C:\OpenSim*\'));
            scripts = matchFiles('C:/Opensim*/**/configureOpenSim.m');
            if isempty(scripts)
                resourcesZip = matchFiles('C:/OpenSim*/Resources.zip');
                if isempty(resourcesZip)
                    error('Could not find script configureOpenSim.m');
                end
                resourcesZip = resourcesZip{1};
                fprintf('Unzipping %s\n', resourcesZip);
                resources = fullfile(fileparts(resourcesZip), 'Resources');
                unzip(resourcesZip, resources);
                scripts = matchFiles('C:/Opensim*/**/configureOpenSim.m');
            end
        end
        if numel(scripts) > 1
            warning('There may be multiple installations of OpenSim. Defaulting to installation in %s.', fileparts(scripts{1}));
        end
        run(scripts{1});
        openSimJustAdded = true;
    catch e
        warning(e.getReport);
        if isequal(e.identifier, 'MATLAB:FileIO:InvalidFid')
            warning('You may need to run install() as admin.');
        end
        error('Could not install sf_pre. Is OpenSim installed?');
    end
end

savepath();
fprintf('Scripts added to path...\n');
fprintf('Path saved...\n');
fprintf(['If you are new to using this repo, please see <a href="matlab:open(''./+Osim/examples/example.m'')">+Osim/examples/example.m</a> ' ...
'for information on how to use OpenSim\nvia MATLAB, or <a href="matlab:open(''./+Vicon/examples/example.m'')">+Vicon/examples/example.m</a> ' ...
'for information on automated iterative gap-filling via MATLAB.\n']);
if openSimJustAdded
    fprintf('Please restart MATLAB.\n');
end
